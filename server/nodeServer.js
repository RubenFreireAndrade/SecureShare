if (process.env.NODE_ENV !== 'production') {
  require('dotenv').config();
};

class User {
  constructor(name, publicKey){
    this.name = name;
    this.publicKey = publicKey;
  }

  saveUser() {
    // Save the user to a database?
  }
}

const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');

const PORT = 3000;
const app = express();

app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

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

app.post('/register', function(req, res) {
  // Get JSON data?
  const { userName, publicKey } = req.body;

  if (res.status(200)) {
    
    // TODO: Save the user data to a database.
    // Check if it was a success then return a message back to Client.

    // return JSON ??
    res.json({ message: "User registered!"})
  }
});

app.listen(PORT, function () {
  console.log('listening to port');
});





// // Define the endpoint for registering a user
// app.post('/register', (req, res) => {
//   // Get the username and public key from the request body
//   const { userName, publicKey } = req.body;

//   // TODO: Validate the username and public key inputs here
//   // ...

//   // TODO: Save the user data to a database or other data store here
//   // ...

//   // Send a success response back to the client
//   res.status(200).json({ message: 'User registered successfully' });
// });