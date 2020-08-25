#Dev instance - First time
#	modified:   db/migrate/20160712171303_add_remove_odsa_module_progress_fk.rb
Deleted inst_module_id column + Foreign Key

#	modified:   db/migrate/20170715223741_change_user_id_and_lms_instance_id_to_not_null.rb

#bundle exec rake db:reset_populate
#Polulate db with data from: ./lib/tasks/sample_data.rake

#Download RST data. Need to be move under public directory
#cp -rf ../OpenDSA-master/RST/ public/OpenDSA
#cp -rf ../OpenDSA-master/tools/ public/OpenDSA
#public/OpenDSA/config

admin@opendsa.org (pass: adminadmin)
example-1@railstutorial.org (pass: hokiehokie), has instructor access
example-*@railstutorial.org (pass: hokiehokie) 50 students

#run delayed_jobs on the background
RAILS_ENV=${ENVIRONMENT} rake jobs:work

# Update postprocessor.py file to encode:
/opendsa-lti/public/OpenDSA/tools# vim postprocessor.py
Line 188:
terms_dict[term] = str(term_def.encode("utf-8"))

# Compiled Books are stored under:
ie. /opendsa-lti/public/OpenDSA/Books/vt/cs1114/fall-2020/CS1114-FALL2020#
------------------------------------------------------------------------------------------------------

HEADS UP! i18n 1.1 changed fallbacks to exclude default locale.
But that may break your application.

If you are upgrading your Rails application from an older version of Rails:

Please check your Rails app for 'config.i18n.fallbacks = true'.
If you're using I18n (>= 1.1.0) and Rails (< 5.2.2), this should be
'config.i18n.fallbacks = [I18n.default_locale]'.
If not, fallbacks will be broken in your app by I18n 1.1.x.

If you are starting a NEW Rails application, you can ignore this notice.

For more info see:
https://github.com/svenfuchs/i18n/releases/tag/v1.1.0

**Post-install message from sass:**

Ruby Sass has reached end-of-life and should no longer be used.

* If you use Sass as a command-line tool, we recommend using Dart Sass, the new
  primary implementation: https://sass-lang.com/install

* If you use Sass as a plug-in for a Ruby web framework, we recommend using the
  sassc gem: https://github.com/sass/sassc-ruby#readme

* For more details, please refer to the Sass blog:
  https://sass-lang.com/blog/posts/7828841

**Post-install message from acts-as-taggable-on:**
When upgrading

Re-run the migrations generator

    rake acts_as_taggable_on_engine:install:migrations

This will create any new migrations and skip existing ones
Version 3.5.0 has a migration for mysql adapter

**Post-install message from capistrano-passenger:**
==== Release notes for capistrano-passenger ====
passenger once had only one way to restart: `touch tmp/restart.txt`
Beginning with passenger v4.0.33, a new way was introduced: `passenger-config restart-app`

The new way to restart was not initially practical for everyone,
since for versions of passenger prior to v5.0.10,
it required your deployment user to have sudo access for some server configurations.

capistrano-passenger gives you the flexibility to choose your restart approach, or to rely on reasonable defaults.

If you want to restart using `touch tmp/restart.txt`, add this to your config/deploy.rb:

    set :passenger_restart_with_touch, true

If you want to restart using `passenger-config restart-app`, add this to your config/deploy.rb:

    set :passenger_restart_with_touch, false # Note that `nil` is NOT the same as `false` here

If you don't set `:passenger_restart_with_touch`, capistrano-passenger will check what version of passenger you are running
and use `passenger-config restart-app` if it is available in that version.

If you are running passenger in standalone mode, it is possible for you to put passenger in your
Gemfile and rely on capistrano-bundler to install it with the rest of your bundle.
If you are installing passenger during your deployment AND you want to restart using `passenger-config restart-app`,
you need to set `:passenger_in_gemfile` to `true` in your `config/deploy.rb`.
================================================
**Post-install message from ruby-graphviz:**

You need to install GraphViz (https://graphviz.org) to use this Gem.

================================================
 gem install json -v '2.3.0'
 ================================================
 
 bundle config --delete bin    # Turn off Bundler's stub generator
   rails app:update:bin          # Use the new Rails executables
   git add bin                   # Add bin/ to source control
 
 You may need to remove bin/ from your .gitignore as well.
 
 ================================================
 rvm use 2.7.1 -- default
  rvm use 2.7.1@OpenDSA-LTI --default
  
  bundle install --redownload
   gem install rdoc

Rail 4.2
To automatically update from static attributes to dynamic ones,
install rubocop-rspec and run:
rubocop --require rubocop-rspec --only FactoryBot/AttributeDefinedStatically --auto-correct

OpenSSL
https://medium.com/@campbelllssoup/install-bundler-2-macos-when-you-get-error-unable-to-require-openssl-install-openssl-and-8b9ef67525b1
/usr/local/opt/openssl -> /usr/local/Cellar/openssl@1.1/1.1.1g
sudo ln -s /usr/local/Cellar/openssl/1.0.2s/bin/openssl /usr/local/opt/openssl
sudo ln -s /usr/local/Cellar/openssl@1.1/1.1.1g /usr/local/opt/openssl

brew install openssl
openssl version -a

 conflict  config/boot.rb
Overwrite /Users/jihane/Development/code/OpenDSA-LTI/config/boot.rb? (enter "h" for help) [Ynaqdhm] Y
       force  config/boot.rb
       exist  config
       
    conflict  config/routes.rb
Overwrite /Users/jihane/Development/code/OpenDSA-LTI/config/routes.rb? (enter "h" for help) [Ynaqdhm] Y
       force  config/routes.rb
       
    conflict  config/application.rb
Overwrite /Users/jihane/Development/code/OpenDSA-LTI/config/application.rb? (enter "h" for help) [Ynaqdhm] Y
       force  config/application.rb
    conflict  config/environment.rb
Overwrite /Users/jihane/Development/code/OpenDSA-LTI/config/environment.rb? (enter "h" for help) [Ynaqdhm] Y
       force  config/environment.rb
      create  config/cable.yml
    conflict  config/puma.rb
Overwrite /Users/jihane/Development/code/OpenDSA-LTI/config/puma.rb? (enter "h" for help) [Ynaqdhm] Y
       force  config/puma.rb
      create  config/storage.yml
       exist  config/environments
    conflict  config/environments/development.rb
Overwrite /Users/jihane/Development/code/OpenDSA-LTI/config/environments/development.rb? (enter "h" for help) [Ynaqdhm] Y
       force  config/environments/development.rb
    conflict  config/environments/production.rb
Overwrite /Users/jihane/Development/code/OpenDSA-LTI/config/environments/production.rb? (enter "h" for help) [Ynaqdhm] Y
       force  config/environments/production.rb
    conflict  config/environments/test.rb
Overwrite /Users/jihane/Development/code/OpenDSA-LTI/config/environments/test.rb? (enter "h" for help) [Ynaqdhm] Y
       force  config/environments/test.rb
       exist  config/initializers
      create  config/initializers/application_controller_renderer.rb
    conflict  config/initializers/assets.rb
Overwrite /Users/jihane/Development/code/OpenDSA-LTI/config/initializers/assets.rb? (enter "h" for help) [Ynaqdhm] Y
       force  config/initializers/assets.rb
   identical  config/initializers/backtrace_silencers.rb
      create  config/initializers/content_security_policy.rb
      create  config/initializers/cookies_serializer.rb
      create  config/initializers/cors.rb
   identical  config/initializers/filter_parameter_logging.rb
    conflict  config/initializers/inflections.rb
Overwrite /Users/jihane/Development/code/OpenDSA-LTI/config/initializers/inflections.rb? (enter "h" for help) [Ynaqdhm] Y
       force  config/initializers/inflections.rb
    conflict  config/initializers/mime_types.rb
Overwrite /Users/jihane/Development/code/OpenDSA-LTI/config/initializers/mime_types.rb? (enter "h" for help) [Ynaqdhm] Y
       force  config/initializers/mime_types.rb
      create  config/initializers/new_framework_defaults_5_2.rb
    conflict  config/initializers/wrap_parameters.rb
Overwrite /Users/jihane/Development/code/OpenDSA-LTI/config/initializers/wrap_parameters.rb? (enter "h" for help) [Ynaqdhm] Y
       force  config/initializers/wrap_parameters.rb
       exist  config/locales
    conflict  config/locales/en.yml
Overwrite /Users/jihane/Development/code/OpenDSA-LTI/config/locales/en.yml? (enter "h" for help) [Ynaqdhm] Y
       force  config/locales/en.yml
        gsub  config/initializers/cookies_serializer.rb
   identical  config/cable.yml
   identical  config/storage.yml
      remove  config/initializers/cors.rb
       exist  bin
   identical  bin/bundle
   identical  bin/rails
   identical  bin/rake
   identical  bin/setup
   identical  bin/update
   identical  bin/yarn
   
   
   bundle _1.17.3_ update
   gem install bundler:1.17.3