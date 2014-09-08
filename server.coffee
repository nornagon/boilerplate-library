express = require 'express'
http = require 'http'
level = require 'level'

app = express()
app.use express.static "#{__dirname}"


db = level 'db', valueEncoding:'json'

app.get '/data/all', (req, res, next) ->
  stream = db.createReadStream()

  data = []

  stream.on 'data', (entry) ->
    data.push entry.value
  stream.on 'end', ->
    res.send data

  stream.on 'error', (err) -> next(err)


server = http.createServer app
server.listen '4433'
console.log 'listening on 4433'

