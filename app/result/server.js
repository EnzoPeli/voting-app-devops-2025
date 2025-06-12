const express = require('express');
const async = require('async');
const { Pool } = require('pg');
const cookieParser = require('cookie-parser');
const path = require('path');
const app = express();
const server = require('http').Server(app);
const io = require('socket.io')(server);

const port = process.env.PORT || 4000;

io.on('connection', (socket) => {
  socket.emit('message', { text: 'Welcome!' });

  socket.on('subscribe', (data) => {
    socket.join(data.channel);
  });
});

const pool = new Pool({
  connectionString: 'postgres://postgres:postgres@db/postgres'
});

async.retry(
  {times: 1000, interval: 1000},
  function(callback) {
    pool.connect(function(err, client) {
      if (err) {
        console.error('Waiting for db');
      }
      callback(err, client);
    });
  },
  function(err, client) {
    if (err) {
      return console.error('Giving up');
    }
    console.log('Connected to db');
    getVotes(client);
  }
);

function getVotes(client) {
  client.query('SELECT vote, COUNT(id) AS count FROM votes GROUP BY vote', [], function(err, result) {
    if (err) {
      console.error('Error performing query: ' + err);
    } else {
      var votes = collectVotesFromResult(result);
      io.sockets.emit('scores', JSON.stringify(votes));
    }

    setTimeout(function() {getVotes(client); }, 1000);
  });
}

function collectVotesFromResult(result) {
  var votes = {a: 0, b: 0};

  result.rows.forEach(function (row) {
    votes[row.vote] = parseInt(row.count);
  });

  return votes;
}

app.use(cookieParser());
app.use(express.urlencoded());
app.use(express.static(__dirname + '/views'));

app.get('/', function (req, res) {
  res.sendFile(path.resolve(__dirname + '/views/index.html'));
});

server.listen(port, function () {
  var port = server.address().port;
  console.log('App running on port ' + port);
});
