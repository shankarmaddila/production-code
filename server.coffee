port = process.env.PORT or 5000
express = require("express")
_ = require("underscore")
multer = require("multer")
azure = require('azure-storage')

upload = multer({ dest: 'uploads/' })
app = express()

# The file upload element name
type = upload.single('file')

app.all "*", (req, res, next) ->
  return next()  unless req.get("Origin")
  res.set "Access-Control-Allow-Origin", "*"
  res.set "Access-Control-Allow-Methods", "GET"
  res.set "Access-Control-Allow-Headers", "X-Requested-With, Content-Type"
  # use "*" here to accept any origin
  # res.set('Access-Control-Allow-Max-Age', 3600);
  return res.sendStatus(200)  if "OPTIONS" is req.method 
  next()
  return

app.post '/upload', type, (req, res) ->
  # req.file is the `file` file
  # req.body will hold the text fields, if there were any
  console.log req.file
  share = 'datafiles'
  options = {}
  fileService = azure.createFileService("interfacecampaigns","cfiEpxphPrJzIsI8bL5a5hCSF5Rn1zFVWPcm3Z323IFA+dbmpr9xgSHm1hXHz24x4d+4Z5tU/Ri+70VL7Lh09g==")
  fileService.createShareIfNotExists share, (error, result, response)=>
    if !error
      # if result = true, share was created.
      # if result = false, share already existed.
      newFileName = Date.now() + '.csv'
      fileService.createDirectoryIfNotExists share, "qa", options, (error, result, response)->
        if !error
          fileService.createFileFromLocalFile share, "qa", newFileName, req.file.path, (error, result, response) ->
            if !error
              # file uploaded
              console.log "uploaded " + newFileName
              res.writeHead(200, { Connection: 'close' })
              require('./trigger_publish.js') res
            else
              console.log error
            return
        else
          console.log error
    else
      console.log error
    return
  return

app.get "/upload", (req, res) ->
  res.writeHead(200, { Connection: 'close' })
  res.end('<html><head></head><body>\
             <form method="POST" action="/upload" enctype="multipart/form-data">\
              <input type="text" name="textfield"><br />\
              <input type="file" name="file"><br />\
              <input type="submit">\
            </form>\
          </body></html>')
  return

app.get "/api/publish", (req, res) ->
  require('./trigger_publish.js') res
  return
app.get "/api/publish/history", (req, res) ->
  require('./trigger_publish_history.js') res
  return
app.listen port
console.log "express listening at port: "+port
oneDay = 86400000
app.use('/', express.static(__dirname + '/build', { maxAge: oneDay }))

app.use(express.static(__dirname + '/build', { maxAge: oneDay }))