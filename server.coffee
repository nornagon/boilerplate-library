express = require 'express'
http = require 'http'
level = require 'level'
bodyParser = require 'body-parser'

app = express()
app.use express.static "#{__dirname}/public"
app.use '/assets', express.static "#{__dirname}/assets"
app.use bodyParser.json()

db = level 'db', valueEncoding:'json'

app.get '/data/all', (req, res, next) ->
  stream = db.createReadStream()

  data = []

  stream.on 'data', (entry) ->
    v = entry.value
    v.id = entry.key
    data.push v
  stream.on 'end', ->
    res.send data

  stream.on 'error', (err) -> next(err)

app.post '/data', (req, res, next) ->
  return next 'Missing body' unless typeof req.body is 'object'
  id = "entry.#{Date.now()}"
  db.put id, req.body, (err) ->
    return next err if err
    res.send {id}

app.put '/data/:id', (req, res, next) ->
  return next 'Missing body' unless typeof req.body is 'object'
  delete req.body.id
  db.put req.params.id, req.body, (err) ->
    return next err if err
    res.send {ok:true}

app.delete '/data/:id', (req, res, next) ->
  db.del req.params.id, (err) ->
    return next err if err
    res.send {ok:true}

server = http.createServer app
server.listen '4433'
console.log 'listening on 4433'

