publish = function(res){
    var request = require('request'),
        username = "$interface-specials-framework",
        password = "6L2CDDgZ0a1odMNX0bHZc7Aed1pMwZwZoG1RufG4g3lgFoD5Mtrxo5E58l5j",
        url = "https://interface-specials-framework.scm.azurewebsites.net/api/triggeredwebjobs/publish/run",
        auth = "Basic " + new Buffer(username + ":" + password).toString("base64");

    request(
        {
            method: 'POST',
            url : url,
            headers : {
                "Authorization" : auth
            }
        },
        function (error, response, body) {
            if(error){
                console.log(error);
            }

            res.write(body)
            res.end()
        }
    );
}

module.exports = publish