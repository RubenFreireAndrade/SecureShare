if (process.env.NODE_ENV !== 'production') {
  require('dotenv').config();
};

const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const path = require('path');
const fs = require('fs');

const PORT = 3000;
const app = express();

app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

app.get('/file', (req, res) => {
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
    url: 'http://localhost:3000/download',
    type: 'text',
  }]);
});

app.get('/user/:name', (req, res) => {
  res.send('Hello: ' + req.params.name);
});

app.get('/download', function(req,res) {
  res.download(__dirname + '/test.txt', function(err) {
    if(err) {
      console.log(err);
    }
  });
});

app.get('/download1', function(req,res) {
  res.download(__dirname + '/snowmountain.jpg', function(err) {
    if(err) {
      console.log(err);
    }
  });
});

app.get('/download2', function(req,res) {
  res.download(__dirname + '/test.txt', function(err) {
    if(err) {
      console.log(err);
    }
  });
});

// app.get(url, function(req, res) {
//   const fileStream = fs.createWriteStream('../app/data');
//   res.pipe(fileStream);
//   fileStream.on('finish', function() {
//     fileStream.close();
//     console.log('Download Complete!');
//   })
// })

app.listen(PORT, function () {
  console.log('listening to port');
});

