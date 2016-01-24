Here we describe how to install [OpenDSA-LTI](https://github.com/OpenDSA/OpenDSA-LTI) on a single Ubuntu Server 14.04.3 LTS 64-bit from scratch.

**Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*

- [Hardware requirements](#hardware-requirements)
- [Installation instructions](#installation-instructions)
  - [Prepare the system](#prepare-the-system)
  - [Installing Passenger + Apache](#installing-passenger-+-apache)
  - [Deploying OpenDSA-LTI app on Ubuntu server](#Deploying-OpenDSA-LTI-app-on-Ubuntu-server)
  - [Installing OpenDSA dependencies and compile books](#Installing-OpenDSA-dependencies-and-compile-books)

## Hardware requirements

The following server requirements will be fine for supporting hundreds of users.


* **Ubuntu Server 14.04.3 LTS**
* **Minimum 4GB of memory**
* **At least one 2.00GHz CPU**
* **Minimum 25GB of free disk**

## Installation instructions

### Prepare the system

  - Launch an Ubuntu server and login to it as a user that has full sudo  privileges.

  - Update your Ubuntu package sources
    ```
    sudo apt-get update -y
    sudo apt-get upgrade -y
    sudo reboot
    ```

  - Perform the steps below
    ```
    sudo apt-get install -y build-essential software-properties-common python python-dev python-feedvalidator python-software-properties curl git-core libxml2-dev libxslt1-dev libfreetype6-dev python-pip python-apt python-dev libxmlsec1-dev swig libmysqlclient-dev git libevent-dev libffi-dev libssl-dev
    
    sudo apt-get install -y nodejs && sudo ln -sf /usr/bin/nodejs /usr/local/bin/node

    sudo apt-get -y install uglifyjs
    ```

  - Install RVM
    ```
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
    curl -sSL https://get.rvm.io | sudo bash -s stable
    sudo usermod -a -G rvm `whoami`
    ```

    When you are done with all this, **relogin to your server** to activate RVM. This is important: if you don't relogin, RVM doesn't work.

  - Install Ruby version 2.2.3
    ```
    rvm install ruby-2.2.3
    rvm --default use ruby-2.2.3
    ```

  - Install Bundler
    Bundler is a popular tool for managing application gem dependencies.
    ```
    gem install bundler --no-rdoc --no-ri
    ```

### Installing Passenger + Apache

  - Install Passenger packages
    ```
    # Install PGP key and add HTTPS support for APT
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
    sudo apt-get install -y apt-transport-https ca-certificates

    # Add APT repository
    sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main > /etc/apt/sources.list.d/passenger.list'
    sudo apt-get update

    # Install Passenger + Apache module
    sudo apt-get install -y libapache2-mod-passenger
    ```

  - Install apache
    ```
    sudo apt-get install -y apache2 apache2-threaded-dev
    ```

  - Activate the SSL Module
    Enable the module by typing:
    ```
    sudo a2enmod ssl
    ```

  - Enable the Passenger Apache module and restart Apache
    ```
    sudo a2enmod passenger
    sudo service apache2 restart
    ```

  - Check installation
    ```
    sudo passenger-config validate-install

    - Checking whether this Phusion Passenger install is in PATH... ✓
    - Checking whether there are no other Phusion Passenger installations... ✓
    ```
    All checks should pass. If any of the checks do not pass, please follow the suggestions on screen.

    Finally, check whether Apache has started the Passenger core processes. Run `sudo passenger-memory-stats`. You should see Apache processes as well as Passenger processes. For example:
    ```
    sudo passenger-memory-stats

    Version: 5.0.8
    Date   : 2015-05-28 08:46:20 +0200

    ---------- Apache processes ----------
    PID    PPID   VMSize    Private  Name
    --------------------------------------
    3918   1      190.1 MB  0.1 MB   /usr/sbin/apache2
    ...

    ----- Passenger processes ------
    PID    VMSize    Private   Name
    --------------------------------
    12517  83.2 MB   0.6 MB    Passenger watchdog
    12520  266.0 MB  3.4 MB    Passenger core
    12531  149.5 MB  1.4 MB    Passenger ust-router
    ...
    ```
  
  - Update regularly
    Apache updates, Passenger updates and system updates are delivered through the APT package manager regularly. You should run the  following command regularly to keep them up to date:
    ```
    sudo apt-get update -y
    sudo apt-get upgrade -y
    ```
    You do not need to restart Apache or Passenger after an update, and you also do not need to modify any configuration files after an update. That is all taken care of automatically for you by APT.

### Deploying OpenDSA-LTI app on Ubuntu server
  - Login to your server, create opendsa user
    Login to your server with SSH:
    ```
    ssh adminuser@yourserver.com
    ```
    Replace `adminuser` with the name of an account with administrator privileges or sudo privileges.

    Now that you have logged in, you should create an operating system user account for OpenDSA-LTI. For security reasons, it is a good idea to run each app under its own user account, in order to limit the damage that security vulnerabilities in the app can do. Passenger will automatically run your app under this user account as part of its user account sandboxing feature.

    ```
    sudo adduser opendsa
    ```
    We also ensure that that user has your SSH key installed:

    ```
    sudo mkdir -p ~opendsa/.ssh
    sudo sh -c "cat $HOME/.ssh/authorized_keys >> ~opendsa/.ssh/authorized_keys"
    sudo chown -R opendsa: ~opendsa/.ssh
    sudo chmod 700 ~opendsa/.ssh
    sudo sh -c "chmod 600 ~opendsa/.ssh/*"
    ```

  - Clone OpenDSA-LTI and OpenDSA repositories
    ```
    sudo mkdir -p /home/lti
    sudo chown opendsa: /home/lti
    cd /home/lti
    sudo -u opendsa -H git clone https://github.com/OpenDSA/OpenDSA-LTI.git
    sudo -u opendsa -H git clone https://github.com/OpenDSA/OpenDSA.git
    ```

  - Login as the `opendsa` user

    All subsequent instructions must be run under the `opendsa` account. While logged into your server, login under the `opendsa` account as follows:
    ```
    sudo -u opendsa -H bash -l
    ```
    
    Since you are using RVM, make sure that you activate the Ruby version that you want to run your app under. For example:
    ```
    rvm use ruby-2.2.3
    ```

  - Install OpenDSA-LTI app dependencies
    ```
    cd /home/lti/OpenDSA-LTI
    bundle install --deployment --without development test
    ```
  - Configuring Apache and Passenger
    It is time to configure Apache so that Passenger knows how to serve your app. To determine the Ruby command that Passenger should use run the following command:
    ```
    passenger-config about ruby-command

    passenger-config was invoked through the following Ruby interpreter:
    Command: /usr/local/rvm/gems/ruby-2.2.3/wrappers/ruby
    Version: ruby 2.2.3p85 (2015-02-26 revision 49769) [x86_64-linux]
    ...
    ```
    
    Please take note of the path after "Command" (in this example, `/usr/local/rvm/gems/ruby-2.2.3/wrappers/ruby`). You will need it in one of the next steps.

  - Go back to the admin account
    You have previously logged in using `opendsa` user account in order to prepare the OpenDSA-LTI environment. That user does not have sudo access. In the next steps, you need to edit configuration files, for which sudo access is needed. So you need to switch back to the admin account.

    This can be done by simply exiting the shell that was logged into the `opendsa` user account. You will then be dropped back to the admin account. For example:
    ```
    # This is what you previously ran:
    admin$ sudo -u opendsa -H bash -l
    opendsa$ ...

    # Type `exit` to go back to the account you were before
    opendsa$ exit
    admin$ _
    ```

  - Edit Apache configuration file
    We need to create an Apache configuration file and setup a virtual host entry that points to OpenDSA-LTI. This virtual host entry tells Apache (and Passenger) where your OpenDSA-LTI is located.
    ```
    sudo nano /etc/apache2/sites-enabled/opendsa-ssl.conf
    ```
    Put this inside the file:
    ```
    <IfModule mod_ssl.c>
    <VirtualHost _default_:443>
        ServerAdmin webmaster@yourserver.com
        ServerName yourserver.com
        DocumentRoot /home/lti/OpenDSA-LTI/public

        PassengerRuby /path-to-ruby

        <Directory /home/lti/OpenDSA-LTI/public>
          Allow from all
          Options -MultiViews
          Require all granted
        </Directory>

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined

        SSLEngine on
        SSLCertificateFile /path-to-certificate-file
        SSLCertificateKeyFile /path-to-key-file
        SSLProtocol all -SSLv2 -SSLv3
        SSLCipherSuite AES128+EECDH:AES128+EDH
        SSLCompression off
    </VirtualHost>
    </IfModule>
    ```
    Replace `yourserver.com` with your server's host name, replace `path-to-certificate-file` with your certificate file path, and replace `path-to-key-file` with your certificate key file path. Finally replace `path-to-ruby` with the Ruby command that you obtained earlier.

    When you are done, restart Apache:
    ```
    sudo service apache2 restart
    ```

  - Test drive
    You should now be able to access your app through the server's host name! Try running this from your local computer. Replace `yourserver.com` with your server's hostname, exactly as it appears in the Apache config file's `ServerName` directive.

    ```
    curl http://yourserver.com/
    ...your app's front page HTML...
    ```

  - Create link to OpenDSA repository
    ```
    sudo ln -s /home/lti/OpenDSA /home/lti/OpenDSA-LTI/public
    ```

### Installing OpenDSA dependencies and compile books

  Now we are finished with deploying OpenDSA-LTI, we have to install OpenDSA dependencies to be able to combile books.

  - Install OpenDSA dependencies
    ```
    cd /home/lti/OpenDSA
    sudo pip install -r requirements.txt --upgrade
    ```

  - Login as the `opendsa` user to compile books
    ```
    sudo -u opendsa -H bash -l
    cd /home/lti/OpenDSA
    make pull
    make <<book_config_file>>
    ```
