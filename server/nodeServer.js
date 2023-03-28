if (process.env.NODE_ENV !== 'production') {
  require('dotenv').config();
};

const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const redis = require('redis');
const { promisify } = require('util');

const PORT = 3000;
const app = express();

app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

const redisClient = redis.createClient();
const redisSetAsync = promisify(redisClient.set).bind(redisClient);

async function saveUserDataToRedis(userName, publicKey) {
  await redisSetAsync(userName, publicKey);
}

function validateUserInput(userName, publicKey) {
  const error = "";

  if (!userName || userName.trim().length < 3 || userName.trim().length < 20) {
    error.push("Username must be between 3 and 20 characters long");
  }

                              // check comparison with database.
  if (!publicKey || !/^\-{5}BEGIN PUBLIC KEY\-{5}\n[0-9a-zA-Z\n\/\+\=]+\n\-{5}END PUBLIC KEY\-{5}$/.test(publicKey.trim())) {
    error.push("Public Key must be a valid RSA Public Key");
  }

  return error;
}

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

app.get('/user/:name', (req, res) => {
  res.send('Hello: ' + req.params.name);
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

app.post('/register', async function(req, res) {
  const { userName, publicKey } = req.body;

  const error = validateUserInput(userName, publicKey);
  if (error > 0) return res.status(400).json({ error });

  await saveUserDataToRedis(userName, publicKey);

  res.status(200).json({ message: "User resgistered successfully" });
});

app.listen(PORT, function () {
  console.log('listening to port');
});