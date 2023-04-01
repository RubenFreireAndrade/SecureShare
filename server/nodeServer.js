require('dotenv').config();

const NodeRSA = require('node-rsa');

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

//========================================================================
app.get('/files', (req, res) => {
  res.send([{
    name: 'Public',
    url: 'http://localhost:3000/download',
    type: 'text',
  },{
    name: 'Private',
    url: 'http://localhost:3000/download1',
    type: 'image',
  },{
    name: 'Shared',
    url: 'http://localhost:3000/download2',
    type: 'text',
  }]);
});

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