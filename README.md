OpenDSA-LTI
================

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

Ruby on Rails
-------------

This application requires:

- Ruby 2.3.0
- Rails 4.2.6

Learn more about [Installing Rails](http://railsapps.github.io/installing-rails.html).

Getting Started
---------------
1. Clone this repository.
2. Run **bower install** from the root directory. More information on bower [here](http://www.bower.io).
3. Clone the [OpenDSA](https://github.com/OpenDSA/OpenDSA) repository.
4. Set up 2 symbolic links in the root directory of this repository
 * RST - link this to the **RST** folder inside the OpenDSA repository
 * Configuration - link this to the **config** folder within the OpenDSA repository
5. Run a developer instance with ** rails server ** in the root directory  

Documentation and Support
-------------------------

### Project (Configuration Editor)
This is a basic rails application and follows the conventions of a rails application for the most part. In addition to a rails application, this project uses [AngularJS](https://docs.angularjs.org/guide/directive) heavily. I'll go over some of the important pieces specific to this project.

**vendor/assets/bower_components** - this is where bower components are installed.

**app/assets/javascripts/book.coffee.js.erb** - this file is where all the JavaScript for the configuration editor is located. No need to look anywhere else. I'll go over the file in more detail further down.

**app/assets/stylesheets/book.scss** - some css for the configuration editor is located in here.

**app/assets/templates** - Contains all the Angular directive templates. Go [here](https://docs.angularjs.org/guide/directive) for more information on Angular directives. I'll go over these files further down.

**app/controllers/configurations/book_controller.rb** - This is really the only rails controller needed for the configuration editor.

**config/routes.rb** - The routes file.

### book.coffee.js.erb

### templates folder

Issues
-------------


Similar Projects
----------------

Contributing
------------

Credits
-------

License
-------
