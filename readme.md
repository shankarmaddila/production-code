# Interface Specials Framework
##### A [PeopleDesign](http://www.peopledesign.com/) Production

Interface Specials allows the Interface carpet sale team to dynamically upload and transform their product data .csv to a customer facing website. 

Users can browse, filter products, and request samples or dye-lot reservations.

### Admin Panel
The admin panel is where the Interface team manages product data.

[Learn more in the wiki](https://github.com/Peopledesign/interface-specials-framework/wiki/Front-End:-Admin)

### Database
This project uses [Firebase's](https://firebase.google.com/) database feature to store the Specials product data. Client and server apps interface with Firebase to read and write data.

### Webjob
The Specials .csv upload feature uses [Azure's Webjob service](https://docs.microsoft.com/en-us/azure/app-service/web-sites-create-web-jobs) to process the file and write the results to the Database.

### Version Control
[Git](https://git-scm.com) is used for this repository's version control.

### Local Development Requirements
To use this project's development setup, the following applications need to be installed on your machine:
- [Ruby](https://www.ruby-lang.org/en/) & [RubyGems](https://rubygems.org)
- [Git](https://www.google.com/search?q=install%20git&oq=install%20git) 
- [Node](https://nodejs.org/en/)
- [NPM](https://www.npmjs.com/)
- [Bower](https://bower.io/)

### Getting started: Server App
See the [server getting started wiki](https://github.com/Peopledesign/interface-specials-framework/wiki/Server:-Getting-Started) to get started with the server app.

### Getting Started: Front End
See the [front end getting started wiki](https://github.com/Peopledesign/interface-specials-framework/wiki/Front-End:-Getting-Started) to get started with the front end app.

### Project Build
Server and front end files are built separately. Refer to the getting started links above to see the build process for each component.
