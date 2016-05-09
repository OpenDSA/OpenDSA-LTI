OpenDSA-LTI
================

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

Ruby on Rails
-------------

This application requires:

- Ruby 2.3.0
- Rails 4.2.6
- Bower 1.7.7+

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
6. Now just access the site from localhost.

Documentation and Support
-------------------------

### Project (Configuration Editor)
This is a basic rails application and follows the conventions of a rails application for the most part. In addition to a rails application, this project uses [AngularJS](https://docs.angularjs.org/guide/directive) heavily. The UI uses [Bootstrap](http://getbootstrap.com) heavily. I'll go over some of the important pieces specific to this project.

**vendor/assets/bower_components** - this is where bower components are installed.

**app/assets/javascripts/book.coffee.js.erb** - this file is where all the JavaScript for the configuration editor is located. No need to look anywhere else. I'll go over the file in more detail further down.

**app/assets/stylesheets/book.scss** - some css for the configuration editor is located in here.

**app/assets/templates** - Contains all the Angular directive templates. Go [here](https://docs.angularjs.org/guide/directive) for more information on Angular directives. I'll go over these files further down.

**app/controllers/configurations/book_controller.rb** - This is really the only rails controller needed for the configuration editor.

**config/routes.rb** - The routes file.

### book.coffee.js.erb
It's called book.coffee.js.erb, but it's just a JavaScript file. Rails names it this by default.

There are several angular controllers defined in this file. I'm using Angular's **$emit** and **$on** functions to pass data between the controllers.

Drag and drop is implemented in the corresponding Angular directive code for the  draggable elements. I'm using the HTML5 drag and drop API. The API has some restrictions on the type of data that is being transported with the dragging element. One of these restrictions does not allow for element being dragged directly through the API. Therefore, there is a variable called **draggingType** defined globally that is used to check the type of element being dragged. This is useful so we can handle modules and chapters differently when they are being dragged.

### templates folder
This is where all the html for the Angular directives is defined. Each file corresponds to a different directive. Their associated JavaScript Code can be found in the book.coffee.js.erb.

Issues
-------------
- Drag and drop for chapters does not work as expected. Needs some modification.
- RST file parsing needs to be implemented to allow configuration of exercises and scoring.


Similar Projects
----------------

Contributing
------------

Credits
-------

License
-------
