Here we describe how to install [OpenDSA-LTI](https://github.com/OpenDSA/OpenDSA-LTI) on a single Ubuntu Server 14.04.3 LTS 64-bit from scratch.

## Hardware requirements

The following server requirements will be fine for supporting hundreds of users.


* **Ubuntu Server 14.04.3 LTS**
* **Minimum 8GB of memory**
* **At least two 2.00GHz CPU**
* **Minimum 250GB of free disk**

## Installation Instructions

### Install OpenDSA-DevStack on your local machine
  - OpenDSA-LTI is using a remote server automation and deployment tool called [Capistrano](http://capistranorb.com/). Each time you want to deploy new changes to OpenDSA-LTI production server you have to initiate the deployment command from within the develpment environment [OpenDSA-DevStack](https://github.com/OpenDSA/OpenDSA-DevStack).

  - Once you have OpenDSA-DevStack up and running open a new terminal and do the following to generate a pair of authentication keys. **Note:** Do not enter a passphrase.
  ```
  cd OpenDSA-DevStack
  vagrant ssh
  ssh-keygen -t rsa
  ```

  - You will see something similar to the following
  ```
  Generating public/private rsa key pair.
  Enter file in which to save the key (/home/vagrant/.ssh/id_rsa): 
  Enter passphrase (empty for no passphrase): 
  Enter same passphrase again: 
  Your identification has been saved in /home/vagrant/.ssh/id_rsa.
  Your public key has been saved in /home/vagrant/.ssh/id_rsa.pub.
  The key fingerprint is:
  00:54:14:9d:c2:3d:d8:5a:d0:12:ae:0c:d6:09:e6:88 vagrant@vagrant-ubuntu-trusty-64
  The key's randomart image is:
  +--[ RSA 2048]----+
  |  o.o+*X .       |
  |.+ o += x        |
  |E + o o= .       |
  | . o ...         |
  |    o   S        |
  |                 |
  |                 |
  |                 |
  |                 |
  +-----------------+
  ```

### Creating `deploy` user on your production server
  - The first thing we will do on our new server is create the user account we'll be using to run OpenDSA-LTI and work from there. Open a new terminal, ssh to your production server, and do the following
  ```
  sudo adduser deploy
  sudo adduser deploy sudo
  su deploy
  cd
  mkdir .ssh
  cd .ssh
  touch authorized_keys
  ```

  - Before we move forward is that we're going to setup SSH to authenticate via keys instead of having to use a password to login. It's more secure and will save you time in the long run. **Switch back to OpenDSA-DevStack termainal** to append the new public key to `deploy@<prod_server>`:.ssh/authorized_keys and enter `deploy` user password one last time:
  ```
  cd
  cat .ssh/id_rsa.pub | ssh deploy@<prod_server> 'cat >> .ssh/authorized_keys'
  ```
  - For now you can ssh to you production server from within OpenDSA-DevStack without password
  ```
  ssh deploy@<prod_server>
  ```

  - For the next steps, **make sure you are logged in as the `deploy` user on the production server!**

### Installing Ruby

  - The first step is to install some dependencies for Ruby.
  ```
  sudo apt-get update
  sudo apt-get install -y git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libffi-dev dkms libxslt-dev libpq-dev python-dev python-pip python-feedvalidator python-sphinx libmariadbclient-dev libevent-dev libsqlite3-dev
  ```
  - Next we're going to be installing Ruby using rbenv.
  ```
  cd
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
  echo 'eval "$(rbenv init -)"' >> ~/.bashrc
  exec $SHELL

  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
  echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
  exec $SHELL

  rbenv install 2.3.1
  rbenv global 2.3.1
  ruby -v
  ```

  - The last step is to install Bundler
  ```
  gem install bundler
  ```

  - **Run `rbenv rehash` after installing bundler.**

### Installing Nginx

  - Phusion is the company that develops Passenger and they recently put out an official Ubuntu package that ships with Nginx and Passenger pre-installed. We'll be using that to setup our production server because it's very easy to setup.
  ```
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
  sudo apt-get install -y apt-transport-https ca-certificates
  ```

  - Add Passenger APT repository
  ```
  sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main > /etc/apt/sources.list.d/passenger.list'
  sudo apt-get update
  ```

  - Install Passenger & Nginx
  ```
  sudo apt-get install -y nginx-extras passenger
  ```

  - So now we have Nginx and passenger installed. We can manage the Nginx webserver by using the service command:
  ```
  sudo service nginx start
  ```
 
  - Open up the server's IP address in your browser to make sure that nginx is up and running. The service command also provides some other methods such as `restart` and `stop` that allow you to easily restart and stop your webserver.
  - Next, we need to update the Nginx configuration file and update couple of things. You'll want to open up `/etc/nginx/nginx.conf` in your favorite editor or simply use nano:
  ```
  sudo nano /etc/nginx/nginx.conf
  ```
  - First, change user from `www-data` to `deploy` 
  ```
  user `deploy`;
  worker_processes auto;
  pid /run/nginx.pid;

  events {
          worker_connections 768;
          # multi_accept on;
  }
  ...
  ```
  - Second, point Passenger to the version of Ruby that we're using. Find the following lines in the configuration file 
  ```
  ##
  # Phusion Passenger
  ##
  # Uncomment it if you installed ruby-passenger or ruby-passenger-enterprise
  ##
  ```
  - Then put the following two lines right after them
  ```
  passenger_root /usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini;
  passenger_ruby /home/deploy/.rbenv/shims/ruby;
  ```
  - The `passenger_ruby` is the important line here. Once you've changed `passenger_ruby` to use the right version Ruby, you can restart Nginx with the new Passenger configuration.
  ```
  sudo service nginx start
  ```
  - Now that we've restarted Nginx, the OpenDSA-LTI will be served up using the `deploy` user.

### Setting Up MySQL server
  - You can install MySQL server and client from the packages in the Ubuntu repository. As part of the installation process, you'll set the password for the root user. This information will go into your OpenDSA-LTI database.yml file in the future.
  ```
  sudo apt-get install -y mysql-server mysql-client libmysqlclient-dev
  ```

  - Installing the libmysqlclient-dev gives you the necessary files to compile the mysql2 gem which is what Rails will use to connect to MySQL when you setup OpenDSA-LTI application.

  - Now we will create a new database and user `opendsa` for OpenDSA-LTI application. First login to mysql
  ```
  mysql -uroot -p
  ```
  - Then create `opendsa` database
  ```
  CREATE DATABASE opendsa DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;

  GRANT ALL PRIVILEGES ON opendsa.* to 'opendsa'@'localhost'  IDENTIFIED BY '<db_password>';
  FLUSH PRIVILEGES;
  exit
  ```

### Install Node.js and bower

  - Node.js is required by Rails assets pipeline.

  ```
  sudo apt-get install -y nodejs
  sudo ln -s /usr/bin/nodejs /usr/sbin/node
  sudo npm install -g jshint
  sudo npm install -g csslint
  sudo npm install -g bower
  ```

### Clone OpenDSA repository in your production server

  - OpenDSA contains all the book contents that will be served by OpenDSA-LTI Rails application. You only need to clone OpenDSA under `deploy` home directory, Then all the linking between OpenDSA and OpenDSA-LTI will happen automatically through the automated deployment tasks.

  ```
  cd
  git clone https://github.com/OpenDSA/OpenDSA.git
  cd OpenDSA
  make pull
  git checkout LTI_ruby
  cd khan-exercises
  git checkout LTI_ruby
  ```

  - **Note:** As of this writing `OpenDSA/LTI_ruby` branch is used, however in the near future this branch will be merged into `OpenDSA/master` branch. So make sure you monitor OpenDSA repository to know when these two branches got merged to update your production server accordingly.


  - For the next steps, **Switch back to OpenDSA-DevStack termainal**

### Deploy OpenDSA-LTI
  - You need to make some changes to OpenDSA-LTI repository related to your spesific production server. To do that you need to fork [OpenDSA-LTI](https://github.com/OpenDSA/OpenDSA-LTI) to your github account and then add your own repository as a remote to OpenDSA-LTI in OpenDSA-DevStack. This way you can make your own changes to OpenDSA-LTI and keep up to date with the latest changes done in the originial repository.
  - In your OpenDSA-DevStack terminal, add your forked repository, replace `your_username` with you github account
  ```
  cd /vagrant/OpenDSA-LTI
  git remote add forked https://github.com/your_username/OpenDSA-LTI.git
  ```

  - First, in `/vagrant/OpenDSA-LTI/config/deploy.rb` file, change `repo_url` to match you forked repository url. Again replace `your_username` with you github account
  ```
  # config valid only for Capistrano 3.1
  lock '3.2.1'

  set :application, 'OpenDSA-LTI'
  # set :repo_url, 'git://github.com/OpenDSA/OpenDSA-LTI.git'
  set :repo_url, 'git://github.com/your_username/OpenDSA-LTI.git'


  # Default branch is :master
  # ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call
  ...
  ```
  
  - Second, you need to open up `/vagrant/OpenDSA-LTI/config/deploy/production.rb` file to set the server IP address of you production server. Replace `128.173.236.80` with your server IP address.
  ```
  set :stage, :production

  # Simple Role Syntax
  # ==================
  # Supports bulk-adding hosts to roles, the primary server in each group
  # is considered to be the first unless any hosts have the primary
  # property set.  Don't declare `role :all`, it's a meta role.

  role :app, %w{deploy@128.173.236.80}
  role :web, %w{deploy@128.173.236.80}
  role :db,  %w{deploy@128.173.236.80}


  # Extended Server Syntax
  # ======================
  # This can be used to drop a more detailed server definition into the
  # server list. The second argument is a, or duck-types, Hash and is
  # used to set extended properties on the server.
  server '128.173.236.80', user: 'deploy', roles: %w{web app db}, my_property: :my_value
  ...  
  ```

  - Finally, if you have staging server you need to open up `/vagrant/OpenDSA-LTI/config/deploy/staging.rb` file to set the server IP address of you staging server. Replace `128.173.236.221` with your staging server IP address.

  - Commit your changes and push it to `forked` remote 
  ```
  cd /vagrant/OpenDSA-LTI
  git add .
  git commit -m "Add production server details"
  git push forked master
  ```

  - Deploy OpenDSA-LTI for the first time **(this step will fail!)**. But it will create OpenDSA-LTI folder structure in the production server.
  ```
  cd /vagrant/OpenDSA-LTI
  bundle exec cap production deploy
  ```

  - First time deployment failed because the shared files `database.yaml` and `secrets.yaml` weren't created on the production server yet.
  - **Switch back to the production server termainal** and do the following
  ```
  cd /home/deploy/OpenDSA-LTI/shared/config
  touch database.yml
  touch secrets.yml
  ```

  - You need to put database credintials in database.yml and generate a new secret for production and save it in secrets.yml.
  - First update databse.yml
  ```
  cd /home/deploy/OpenDSA-LTI/shared/config
  sudo nano database.yml
  ```

  - Copy the following lines and replace `db_password` with your password
  ```
  production:
     adapter: mysql2
     database: opendsa
     username: opendsa
     password: db_password
     host: localhost
     strict: false

  staging:
     adapter: mysql2
     database: opendsa
     username: opendsa
     password: db_password
     host: localhost
     strict: false     
  ```

  - Second update secrets.yml. To generate a new secret go to OpenDSA-DevStack terminal
  ```
  cd /vagrant/OpenDSA-LTI
  rake secret
  ```

  - A new secret will be generated, copy that string and past it in secrets.yml file on the production server. Open secrets.yml file
  ```
  cd /home/deploy/OpenDSA-LTI/shared/config
  sudo nano secrets.yml
  ```

  - Copy the following lines and replace `secret_string` with your new secret
  ```
  production:
    secret_key_base: secret_string

  staging:
    secret_key_base: secret_string
  ```

  - Now production server is ready for deployment, switch back to OpenDSA-DevStack termainal and execute the following
  ```
  cd /vagrant/OpenDSA-LTI
  bundle exec cap production deploy
  ```

  - If you have configured a staging server you can deploy your changes to the staging server the same way as the production. Switch to OpenDSA-DevStack termainal and execute the following
  ```
  cd /vagrant/OpenDSA-LTI
  bundle exec cap staging deploy
  ```

### Final Steps

  - Adding The Nginx Host. In order to get Nginx to respond with the Rails application, we need to modify it's sites-enabled. Open up `/etc/nginx/sites-enabled/default` in your text editor and we will replace the file's contents with the below configuration. Replace `prod_server_name` with your domain name.

  ```
  server {
          listen 80 default_server;
          listen [::]:80 default_server ipv6only=on;

          listen 443 ssl;

          server_name prod_server_name;
          ssl_certificate /etc/nginx/ssl/nginx.crt;
          ssl_certificate_key /etc/nginx/ssl/nginx.key;

          passenger_enabled on;
          rails_env    production;
          root         /home/deploy/OpenDSA-LTI/current/public;

          # redirect server error pages to the static page /50x.html
          error_page   500 502 503 504  /50x.html;
          location = /50x.html {
              root   html;
          }
  }

  ```

  - Replace /etc/nginx/ssl/nginx.crt and /etc/nginx/ssl/nginx.key with your valid certificate and key. 

  - Restart Nginix web server

  ```
  sudo service nginx restart
  ```

  - **TO BE REMOVED:** To populate your database with initial starter data execute the following

  ```
  bundle exec cap production invoke:rake TASK=db:reset_populate
  ```

  - Go to [https://prod_server_name](https://prod_server_name) you should see OpenDSA Rails application landing page. Congratulations!!!

### Production deployment workflow

  - Production deployment is initiated from the development enviroment. It starts with changes you make to OpenDSA-LTI in OpenDSA-DevStack, or changes made to the originial OpenDSA-LTI repository and you decided to deploy them on your production server. First, test these changes locally using OpenDSA-DevStack development servers, Then commit and push these changes to your OpenDSA-LTI repository. Finally initiate the production deployment command from within OpenDSA-DevStack as shown earlier. It is very important to push your changes to your OpenDSA-LTI repository before production deployment. Everytime you deploy your code Capistrano will go and clone the latest version of your OpenDSA-LTI and perform the deployment tasks.

### Export anonymized OpenDSA-LTI data
- Export databse schema from https://opendsa-server.cs.vt.edu server using MySQL workbench data export tool
- Provision the OpenDSA-DevStack VM
- `vagrant ssh` into the VM
- `cd /vagrant/OpenDSA-LTI`
- `bundle exec rake db:drop`
- `bundle exec rake db:create`
- Connect to your local OpenDSA-DevStack using MySQL workbench and import the data using data import tool
- On OpenDSA-DevStack database do the follwoing:
- Relax the following constraints
    + alter table users drop index email;
    + alter table users drop index slug;
- Change the following configuration on workbench
    + Edit > Preferences > Sql Editor > uncheck the "Safe Updates" 
- Execute the following update statements to anonymize the exported data
    + UPDATE `opendsa`.`users` SET `email` = "example@opendsa.org";
    + UPDATE `opendsa`.`users` SET `slug` = "example@opendsa.org";
    + UPDATE `opendsa`.`users` SET `first_name` = "first_name";
    + UPDATE `opendsa`.`users` SET `last_name` = "last_name";
    + UPDATE `opendsa`.`users` SET `encrypted_password` = "encrypted_password";
- Re-export the anynomized schema from OpenDSA-DevStack.

### Import anonymized OpenDSA-LTI data
- Provision the OpenDSA-DevStack VM
- `vagrant ssh` into the VM
- `cd /vagrant/OpenDSA-LTI`
- `bundle exec rake db:drop`
- `bundle exec rake db:create`
- Connect to your local OpenDSA-DevStack using Mysql workbench and import the anonymized data using data import tool
