require('dotenv').config();

const crypto = require('crypto');

const path = require('path');
const express = require('express');

const PORT = 3000;
const app = express();

app.use(require('cors')());

const bodyParser = require('body-parser');
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

const redis = require('redis');
const redisClient = redis.createClient({
  url: `redis://${process.env.REDIS_USERNAME}:${process.env.REDIS_PASSWORD}@${process.env.REDIS_HOST}:${process.env.REDIS_PORT}`
});

const {Storage} = require('@google-cloud/storage');

const storage = new Storage({
  keyFilename: path.join(__dirname, "./secure-share-382721-a5e9e1a7cc97.json"),
  projectId: "secure-share-382721",
})

const secureBucket = storage.bucket("secure-store");

redisClient.on('connect',() => {
  console.log('Connected to redis successfully!');
})

redisClient.on('error',(error) => {
  console.log('Redis connection error: ', error);
})

app.post('/register', async (req, res) => {
  const { username, publicKey } = req.body;
  await redisClient.set(username, publicKey);
  res.json({ message: `User ${username} registered successfully` });
});

app.get('/public-key/:username', async (req, res) => {
  const { username } = req.params;
  const publicKeyString = await redisClient.get(username);
  if (!publicKeyString) {
    return res.status(404).json({ message: 'User not found' });
  }
  res.json({
    username: username,
    public_key: publicKeyString,
  });
});

app.post('/upload', async (req, res) => {
  const xUserName = req.headers['x-user-name'];
  const xAesKeyIv = req.headers['x-aes-key-iv'];
  const xFileName = req.headers['x-file-name'];
  const xFileType = req.headers['x-file-type'];
  const xFileSize = req.headers['x-file-size'];

  const fileId = crypto.createHash('md5').update(`${xUserName}:${xFileName}`).digest('hex');
  const fileData = {
    name: xFileName,
    type: xFileType,
    eKey: xAesKeyIv,
    size: xFileSize,
  };

  // Create a writeable stream to the GCS file
  const file = secureBucket.file(fileId);
  const writeStream = file.createWriteStream({
    metadata: {
      contentType: 'application/octet-stream',
    },
  });
  
  // Pipe the incoming request data through the GCS write stream
  req.pipe(writeStream);
  
  try {
    // Wait for the file to finish uploading
    await new Promise((resolve, reject) => {
      writeStream.on('finish', async () => {
        await redisClient.set(`${xUserName}:file:${fileId}`, JSON.stringify(fileData))
        resolve()
      });
      writeStream.on('error', reject);

      res.status(200).send(`File uploaded to SecureShare.`);
    });
  } catch (error) {
    console.error(`Error uploading file to SecureShare: ${error.message}`);
    res.status(500).send('Error uploading file to SecureShare.');
  }
});

app.get('/files/:username', async (req, res) => {
  const { username } = req.params;
  const fileRedisKeys = await redisClient.keys(`${username}:file:*`);
  const files = [];
  for (const fileKey of fileRedisKeys) {
    const fileData = JSON.parse(await redisClient.get(fileKey));
    fileData.id = fileKey.split(":")[2];
    files.push(fileData);
  }
  res.status(200).send(files);
});

//========================================================================

app.get('/download', function(req, res) {
  res.download(__dirname + '/test.txt', function(err) {
    if(err) {
      console.log(err);
    }
  });
});

app.get('/download1', function(req, res) {
  res.download(__dirname + '/snowmountain.jpg', function(err) {
    if(err) {
      console.log(err);
    }
  });
});

app.get('/download2', function(req, res) {
  res.download(__dirname + '/test.txt', function(err) {
    if(err) {
      console.log(err);
    }
  });
});

app.listen(PORT, async () => {
  await redisClient.connect();
  console.log(`Server is listening on port ${PORT}`);
});