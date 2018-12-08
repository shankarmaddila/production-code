(->
  # admin triggers this script

  # load dependencies
  azure = require('azure-storage')
  csv = require('csv')
  jsonFile = require('jsonfile')
  _ = require('underscore')
  _s = require('underscore.string')
  request = require('request')
  # Vibrant = require('node-vibrant')
  cmd = require('node-cmd')
  Firebase = require('firebase')
  {parseString} = require 'xml2js'
  
  # initialize values
  missed = 0
  total = 0
  imagesSaved = 0
  options = {}
  imageList = []
  partNumbers = []
  missedPartNumbers = []
  
  # connect to the file storage area
  share = 'datafiles'
  directory = 'qa'
  fileShare = "interfacecampaigns"
  fileShareKey = 'cfiEpxphPrJzIsI8bL5a5hCSF5Rn1zFVWPcm3Z323IFA+dbmpr9xgSHm1hXHz24x4d+4Z5tU/Ri+70VL7Lh09g=='

  # time stamp for naming
  revision = Date.now()
  
  # method to convert a decimal to a percent 
  # returns percent
  toPercent = (num, total) ->
    num / total * 100

  # method to zero fill a number to a particular width
  # returns zero filled number
  zeroFill = (number, width) ->
    # console.log "number:", number
    if !number
      return '00'
    width -= number.toString().length
    if width > 0
      return new Array(width + (if /\./.test(number) then 2 else 1)).join('0') + number
    number + ''

  # method to retrieve latest csv from file storage
  getLatestCSV = (error, result, response) =>
    # extract the file name from directory list
    fileNames = _.pluck(result.entries.files, 'name')
    # get the latest file
    newestFileName = fileNames.pop()
    # log status
    console.log "newestFileName: " + newestFileName
    # get text of latest file and then pass to parseCSV method
    fileService.getFileToText share, directory, newestFileName, options, parseCSV
    
  # method to extract data from csv file format
  # results are passed to extractCustoms method
  parseCSV = (err, result)=>
    # called from getLatestCSV
    # strip special character from header
    result = result.replace(/\#/g,'')

    # once parsed, pass to extractCustoms
    csv.parse result, {
      columns: true
      trim: true
      skip_lines_with_empty_values: true
      skip_empty_lines: true
    }, extractCustoms
    
  # method to extract custom and radstock rows from CSV
  extractCustoms = (err, dataresult)=>
    # Called from parseCSV
    # log status
    console.log "extract customs"
    
    # if we have an error
    if err
      # log it
      console.log err

    # how many products do we have?
    total = dataresult.length
    
    # iterate over the products
    _.each dataresult, (row, index) =>
      # only save large lot Customs
      if( (row.COLOR.indexOf("CUSTOM") > -1) or (row.RADSTOCK is "R") )
        # begin parsing the E1 Item Number
        search = row.E1ITEM.trim()
        # extract size code
        sizeCode = row.E1ITEM.substring(12, 14)
        # standardize size codes to match Scene7 assets
        if sizeCode is "7A"
          sizeCode = "7S"
        if sizeCode is "5B"
          sizeCode = "5S"
        # # if the E1 Item number ends in R, it is a Radstock product
        # if search.lastIndexOf("R") is (search.length - 1)
        #   # we'll only search against the first few characters to avoid inconsistencies
        #   scene7search = search.slice(0, -7)
        # else
        scene7search = search.slice(0, -7)
        
        # now build up a scene7 SOAP request using the size code and search string
        scene7request = '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><SOAP-ENV:Header><authHeader xmlns="http://www.scene7.com/IpsApi/xsd/2016-01-14-beta"><user>scott+api@peopledesign.com</user><password>enW1L6JjxL$</password><locale>en-US</locale><appName>Adobe.Scene7.SPS</appName><appVersion>6.10-194940</appVersion><faultHttpStatusCode>200</faultHttpStatusCode></authHeader></SOAP-ENV:Header><SOAP-ENV:Body><searchAssetsByMetadataParam xmlns="http://www.scene7.com/IpsApi/xsd/2016-01-14-beta"><companyHandle>c|28267</companyHandle><filters><includeSubfolders>true</includeSubfolders><assetTypeArray><items>Image</items></assetTypeArray><excludeByproducts>false</excludeByproducts><trashState>NotInTrash</trashState></filters><metadataConditionArray>'
        scene7request += '<items><fieldHandle>name</fieldHandle><op>StartsWith</op><value>' + scene7search + '</value></items>'
        scene7request += '<items><fieldHandle>name</fieldHandle><op>Contains</op><value>' + sizeCode + '</value></items>'
        scene7request += '<items><fieldHandle>name</fieldHandle><op>EndsWith</op><value>_va1</value></items></metadataConditionArray><metadataConditionMatchMode>MatchAll</metadataConditionMatchMode><recordsPerPage>1</recordsPerPage><resultsPage>1</resultsPage><sortBy>created_at</sortBy><sortDirection>Ascending</sortDirection></searchAssetsByMetadataParam></SOAP-ENV:Body></SOAP-ENV:Envelope>'
        
        # wrapper for addImageData so it calls on each row
        addImageDataWithRow = _.partial(addImageData, search, row)
        
        # make a request for the scene7 api request passing the result to the bound date method
        request.post(
          url:'https://s7sps1apissl.scene7.com/scene7/services/IpsApiService',
          body: scene7request,
          headers: 
            "SOAPAction": "searchAssetsByMetadata"
            "Content-Type": "text/xml", 
            "charset":"utf-8"
          ,
          addImageDataWithRow)
      else
        # else skipped it if it's not a radstock or custom product
        missed++
    
  # method to parse Scene7 response and build JSON data view
  addImageData = (search,row, err, response, body)=>
    # called from extractCustoms with Row data
    # if we encounter an error
    console.log "addImageData"
    if err
      # log it and exit
      # throw console.log(err)
      console.log err
      console.log row
      console.log body

    # parse the body to json
    parseString body, (err, result) ->
      if result['soapenv:Envelope']['soapenv:Body'][0]['soapenv:Fault']
        console.log JSON.stringify result['soapenv:Envelope']['soapenv:Body'][0]
      #  [ { 'soapenv:Fault': [ [Object] ] } ]
      totalRows = result['soapenv:Envelope']['soapenv:Body'][0].searchAssetsByMetadataReturn[0].totalRows[0]
      results = result['soapenv:Envelope']['soapenv:Body'][0].searchAssetsByMetadataReturn[0].assetSummaryArray[0]
        
      console.log results
      # if we have a result
      if results
        # extract the filename
        assetName = results.items[0].filename[0]
        
        # if we have an asset
        if assetName
          # build the url of the asset
          path = 'http://media.interface.com/is/image/InterfaceInc/' + assetName
          # create product row with information we've gathered so far
          imageList.push
            'id': search
            'url': path
            'assetName': assetName
            'product': row
          # console.log(imageList.length,total - missed)
      else
        # else we didn't get an asset
        missed++
        # save it for later to report to Graeme Ripley
        missedPartNumbers.push search
        # log status
        console.log 'missed ' + search
      console.log total,missed,imageList.length
      if imageList.length == total - missed
        
        console.log 'ready to pull colors'
        # trigger method to extract color information, passing the response to the dyelot rollup method
        return extractColors imageList, saveJSON
  
  # method to extract color information from product row
  extractColors = (images, callback)=>
    # called from addImageData with Row
    # load required firebase
    Firebase = require('firebase')
    # log status
    console.log 'extract colors'
    
    # attribute reference for backing code
    backingCodeMap = 
      "2500": ["50cm x 50cm","GlasBac® Tile"]
      "250H": ["50cm x 50cm","GlasBac® RE Tile"]
      "250A": ["50cm x 50cm","NexStep® Tile"]
      "250M": ["50cm x 50cm","NexStep® Tile"]
      "250E": ["50cm x 50cm","GlasBac® RE Tile"]

      "2000": ["1m x 1m" ,"GlasBac® Tile"]
      "200H": ["1m x 1m","GlasBac® RE Tile"]
      "200A": ["1m x 1m","NexStep® Tile"]
      "200M": ["1m x 1m","NexStep® Tile"]
      "200E": ["1m x 1m","GlasBac® RE Tile"]

      "AB00": ["50cm x 1m","GlasBac® Tile"]
      "AB0H": ["50cm x 1m","GlasBac® RE Tile"]
      "AB0A": ["50cm x 1m","NexStep® Tile"]
      "AB0E": ["50cm x 1m","GlasBac® RE Tile"]
      "AB0M": ["50cm x 1m","NexStep® Tile"]

      "AK00": ["25cm x 1m","GlasBac® Tile"]
      "AK0H": ["25cm x 1m","GlasBac® RE Tile"]
      "AK0A": ["25cm x 1m","NexStep® Tile"]
      "AK0M": ["25cm x 1m","NexStep® Tile"]
      "AK0E": ["25cm x 1m","GlasBac® RE Tile"]

      "AK0F": ["25cm x 1m","Cushionbac Renew Tile"]
      "AB0F": ["50cm x 1m","Cushionbac Renew Tile"]
      "200F": ["1m x 1m","Cushionbac Renew Tile"]
      "250F": ["50cm x 50cm","Cushionbac Renew Tile"]

      "AK01": ["25cm x 1m","Moisturegard Plus Tile"]
      "AB01": ["50cm x 1m","Moisturegard Plus Tile"]
      "2001": ["1m x 1m","Moisturegard Plus Tile"]
      "2501": ["50cm x 50cm","Moisturegard Plus Tile"]

      "AK03": ["25cm x 1m","Super Cushion Tile"]
      "AB03": ["50cm x 1m","Super Cushion Tile"]
      "2003": ["1m x 1m","Super Cushion Tile"]
      "2503": ["50cm x 50cm","Super Cushion Tile"]

    # attribute reference for size code
    sizeMap =
      '5B': '50 cm x 50 cm'
      '5S': '50 cm x 50 cm'
      '1B': '1 m x 1 m'
      '7A': '25 cm x 1 m'
      '7B': '50 cm x 1m'
      '7C': '25 cm x 50 cm'
      '4B': 'unknown'
      '3B': 'unknown'
      '8S': 'unknown'
      '7S': '25 cm x 1 m'

    # attribute reference for default configuration
    configMap =
      'Ashlar': '15'
      'Brick': '25'
      'Monolithic': '03'
      'Non-Directional': '09'
      'Quarterturn': '05'
      'Quarter-Turn': '05'
      'Herringbone': '29'

    # attribute reference for all known configurations
    installMap =
      '00': 'Monolithic'
      '01': 'Quarter-Turn'
      '02': 'Monolithic'
      '03': 'Monolithic'
      '04': 'Monolithic'
      '05': 'Quarter-Turn'
      '06': ''
      '07': ''
      '08': 'Ashlar'
      '09': 'Non-Directional'
      '10': 'Herringbone'
      '11': 'Ashlar'
      '12': 'Brick'
      '13': 'Brick'
      '14': 'Brick'
      '15': 'Ashlar'
      '16': 'Ashlar'
      '17': 'Monolithic'
      '18': 'Brick'
      '19': 'Ashlar'
      '20': 'Brick'
      '21': 'Brick'
      '22': 'Non-Directional'
      '23': 'Brick'
      '24': 'Brick'
      '25': 'Brick'
      '26': 'Ashlar'
      '27': 'Brick'
      '28': 'Ashlar'
      '29': 'Herringbone'
      '30': 'Brick'
      '31': 'Ashlar'
      '32': 'Brick'
      '33': 'Ashlar'
      '34': ''
      '99': 'Sample'
      'NA': ''

    
    # exract attributes into arrays
    imageURLs = _.pluck(images, 'url')
    partNumbers = _.pluck(images, 'id')
    products = _.pluck(images, 'product')
    assetNames = _.pluck(images, 'assetName')
    
    # how many images?
    total = images.length
    
    # prep new vars
    imageInfo = {}
    images = []
    synced = 0

    # get reference to destination data node
    myFirebaseRef = new Firebase("https://interfacespecials.firebaseio.com/products/" + revision)
    
    # log status
    console.log "Revision: ",revision

    # iterate over images
    _.each imageURLs, (image, index) =>
      # begin parsing the information into displayable format
      # clean up color name
      colorName = _s.titleize(products[index].COLOR.split(' ')[0])
      # break out the color number from the Third Item number
      colorNumber = products[index].THIRDITEM.split('.')[1]
      # break out the pattern number from the Third Item number
      patternNumber = products[index].THIRDITEM.split('.')[2].split("M")[1]
      # if we have a pattern number
      if patternNumber?
        # prepend an M
        patternNumber = "M" + patternNumber
      # zerofill the install code 
      installCode = zeroFill(products[index].INSTALLMTH, 2)
      # find the label by reference
      installLabel = installMap[installCode]
      # set to empty string if null
      installLabel = '' if not installLabel?
      # extract backing code from 3rd item number and get backing name from map
      firstThird = products[index].THIRDITEM.split('.')[0]

      backingName = ""
      # if we have a first third
      if firstThird?
        # the backing code is in the last 4 characters
        backingCode = firstThird.substr(firstThird.length - 4)
        # If we have a match in the backing code map, then extract the backing name from array
        if backingCodeMap[backingCode]?
          backingName = backingCodeMap[backingCode][1]
        
      # clean up the dyelot
      lot = _s.trim(products[index].LOT)
      # extract the product name from the description
      name = _s.titleize(products[index].DESC.split('.')[0])
      # extract the quantity
      quantity = parseFloat(products[index].AVAILQTY.replace(',',''))
      # determine the appropriate warranty information. Radstock product is covered by warranty, customs are not
      warranty = if products[index].E1ITEM.slice(-1) == 'R' then false else true
      # size = products[index].THIRDITEM.split('.')[2].split("M")[0]
      size = products[index].E1ITEM.substring(12, 14)
      # find the size label by reference
      sizeLabel = sizeMap[size]

      # now build the product row
      product =
        'colorName': colorName
        'colorNumber': colorNumber
        'install': installCode
        'installLabel': installLabel
        'backing': backingName
        'lot': lot
        'name': name
        'quantity': quantity
        'warranty': warranty
        'size': size
        'sizeLabel': sizeLabel
      # ensure pattern number 
      product.patternNumber = patternNumber if patternNumber?
      
      # extract the base tile file name from the asset reference
      baseTile = assetNames[index].split('_va1')[0]
      
      # populate 3 images using the available information
      images[index] =
        'tile': 'baseURL': 'http://media.interface.com/is/image/InterfaceInc/' + baseTile + "_va1"
        'config': 'baseURL': 'http://media.interface.com/is/image/InterfaceInc/install_' + configMap[installLabel] + '_' + size + '?$tile=InterfaceInc/' + baseTile
        'scene': 'baseURL': 'http://interfaceinc.scene7.com/ir/render/InterfaceIncRender/us_corridor?&resmode=sharp2&qlt=80,1&obj=main&res=45.72&sharp=1&src=is{InterfaceInc/install_' + configMap[installLabel] + '_' + size + '_room?$tile=InterfaceInc/' + baseTile + '}'
      
      # if we've got a row for this partnumber
      if imageInfo[partNumbers[index]]
        # add dyelot
        # console.log "dyelot row: ",product,products[index]

        # populate dyelot object with each instance of a dylot
        imageInfo[partNumbers[index]].dyelots.push
          lot: product.lot
          quantity: product.quantity
        
        # populate dyelot count from array length 
        imageInfo[partNumbers[index]].dyelotCount = imageInfo[partNumbers[index]].dyelots.length
        # extract the dyelot quantities
        dyelotQuantities = _.pluck imageInfo[partNumbers[index]].dyelots, "quantity"
        # prepare to total quantities
        dyelotTotal = 0
        
        # iterate over the dyelots
        _.each dyelotQuantities, (quant)->
          # add up the dyelot quantities
          dyelotTotal += parseFloat quant

        # populate the totals
        imageInfo[partNumbers[index]].dyelotTotal = dyelotTotal
      else 
        # strip out empty column "":"",
        source = JSON.stringify products[index]
        source = source.replace(/\"\":\"\"\,/g,'')
        source = JSON.parse source

        # now populate the final row data
        imageInfo[partNumbers[index]] =
          'id': partNumbers[index]
          'images': images[index]
          'dyelots':[
            'lot': product.lot
            'quantity': product.quantity
          ]
          'dyelotTotal': product.quantity
          'dyelotCount': 1
          'product': product
          'source': source

      # get product row reference
      myFirebaseRef = new Firebase("https://interfacespecials.firebaseio.com/products/" + revision +  "/imageInfo/" + partNumbers[index])
      # method to handle completion event
      onComplete = (error)=>
        # if we get an error, log it
        if (error) 
          console.log('Synchronization failed')
        else
          # success, increment the counter
          synced++
          # if we've got them all
          if imageURLs.length == synced 
            # log status
            console.log "synced " + synced
            # exit
            process.exit()
      # set product row and pass result to onComplete event
      myFirebaseRef.set( imageInfo[ partNumbers[index] ] ,onComplete)
      # increment counter
      imagesSaved++
      # if we've hit them all
      if imagesSaved == total
        # log status
        console.log "we have them all now"
        # return result to rollupDyelots
        callback(imageInfo)

  # method to save the resulting JSON to firebase
  saveJSON = (imageInfo)=>
    # get reference to missing part number list
    myFirebaseRef = new Firebase("https://interfacespecials.firebaseio.com/products/" + revision +  "/missedPartNumbers")
    # populate the value
    myFirebaseRef.set( missedPartNumbers )
    # log status
    console.log "all done"
    
    return true

  # Execution starts here
  # connect to file storage
  fileService = azure.createFileService(fileShare, fileShareKey)
  # get the directory listing and pass to getLatestCSV method
  fileService.listFilesAndDirectoriesSegmented share, directory, options, getLatestCSV
).call this
