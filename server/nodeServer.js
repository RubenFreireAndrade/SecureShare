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
  const { userName, deviceName, publicKey } = req.body;
  await redisClient.set(`device:${userName}:${deviceName}`, publicKey);
  res.json({ message: `User ${userName} registered successfully` });
});

app.post('/login', async (req, res) => {
  const { userName, authKey } = req.body;
  const deviceRedisKeys = await redisClient.keys(`device:${userName}:*`);

  let device = null;
  const devices = [];
  for (const deviceKey of deviceRedisKeys) {
    const deviceName = deviceKey.split(":")[2];
    devices.push(deviceName);

    // Grabbing public of deviceKey.
    const devicePublicKey = await redisClient.get(deviceKey);

    // Convert the base64-encoded encrypted data to a Buffer
    const encryptedData = Buffer.from(authKey, 'base64url');

    // Decrypt the encrypted data using the public key
    const decryptedData = crypto.publicDecrypt(devicePublicKey, encryptedData);

    // Convert the decrypted data to a string
    const decryptedUserName = decryptedData.toString('base64');
    if (decryptedUserName == userName) {
      device = deviceName;
    }
  }

  res.json({ devices, device });
});

app.get('/:userName/:deviceName', async (req, res) => {
  const { userName, deviceName } = req.params;
  const publicKeyString = await redisClient.get(`device:${userName}:${deviceName}`);
  if (!publicKeyString) {
    return res.status(404).json({ message: 'Device not found' });
  }
  res.json({
    userName: userName,
    deviceName: deviceName,
    public_key: publicKeyString,
  });
});

app.post('/upload', async (req, res) => {
  const userName = req.headers['x-user-name'];
  const deviceName = req.headers['x-device-name'];
  const eKey = req.headers['x-e-key'];
  const fileName = req.headers['x-file-name'];
  const fileType = req.headers['x-file-type'];
  const fileSize = req.headers['x-file-size'];

  const fileId = crypto.createHash('md5').update(`${userName}:${fileName}`).digest('hex');

  const fileData = {
    name: fileName,
    type: fileType,
    eKey: eKey,
    size: fileSize,
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
        await redisClient.set(`file:${userName}:${fileId}`, JSON.stringify(fileData))
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

app.get('/:userName/:deviceName/files', async (req, res) => {
  const { userName, deviceName } = req.params;
  const fileRedisKeys = await redisClient.keys(`file:${userName}:*`);

  const files = [];
  for (const fileKey of fileRedisKeys) {
    const fileData = JSON.parse(await redisClient.get(fileKey));
    fileData.id = fileKey.split(":")[2];
    files.push(fileData);
  }
  res.status(200).send(files);
});

app.get('/:userName/:deviceName/:fileId', async function(req, res) {
  const { userName, deviceName, fileId } = req.params;

  try {
    const fileData = await redisClient.get(`file:${userName}:${fileId}`);
    if (!fileData) {
      res.status(404).send("File not found.");
      return;
    }

    const file = secureBucket.file(fileId);
    const readStream = file.createReadStream();

    // Set headers for the response
    res.setHeader('Content-Type', 'application/octet-stream');

    readStream.pipe(res);
  } catch (error) {
    console.error(`Error downloading file from SecureShare: ${error.message}`);
    res.status(500).send('Error downloading file from SecureShare.');
  }
});

app.listen(PORT, async () => {
  await redisClient.connect();
  console.log(`Server is listening on port ${PORT}`);
});