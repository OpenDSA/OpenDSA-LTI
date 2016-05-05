#!/usr/bin/env bash

# Function to issue sudo command with password
function sudo-pw {
    echo "vagrant" | sudo -S $@
}

# Start configuration
sudo-pw apt-get -y update

sudo-pw apt-get -y install dkms
sudo-pw apt-get -y install curl
sudo-pw apt-get -y install screen
sudo-pw apt-get -y install libxml2-dev libxslt-dev
sudo-pw apt-get -y install nodejs
sudo-pw apt-get -y install git
sudo-pw apt-get -y install libpq-dev
sudo-pw apt-get -y install vim
sudo-pw apt-get -y install emacs
sudo-pw apt-get -y install python
sudo-pw apt-get -y install python-feedvalidator
sudo-pw apt-get -y install python-software-properties
sudo-pw apt-get -y install libmysqlclient-dev
sudo-pw apt-get -y install libmariadbclient-dev
sudo-pw apt-get -y install libcurl4-gnutls-dev
sudo-pw apt-get -y install python-pip
sudo-pw apt-get -y install libevent-dev
sudo-pw apt-get -y install libffi-dev
sudo-pw apt-get -y install libssl-dev
sudo-pw apt-get -y install python-dev
sudo-pw apt-get -y install build-essential
sudo-pw apt-get -y install stunnel4
sudo-pw apt-get -y install default-jre

sudo-pw apt-get -y autoremove
sudo-pw apt-get -y update

# Clone OpenDSA
if [ ! -d /vagrant/public/OpenDSA ]; then
  sudo-pw git clone https://github.com/OpenDSA/OpenDSA.git /vagrant/public/OpenDSA
fi

# Checkout LTI branch
cd /vagrant/public/OpenDSA/

sudo-pw apt-get -y install python-sphinx
sudo-pw curl -sL https://deb.nodesource.com/setup | sudo bash -
sudo-pw apt-get -y install nodejs
sudo-pw apt-get -y install uglifyjs
sudo-pw apt-get -y install uglifycss
sudo-pw ln -s /usr/bin/nodejs /usr/bin/node
sudo-pw ln -s /usr/bin/nodejs /usr/sbin/node
sudo-pw npm install -g jshint
sudo-pw npm install -g csslint
cd /vagrant/public/OpenDSA/
sudo-pw pip install -r requirements.txt --upgrade
make pull

# Clone OpenDSA-LTI
# if [ ! -d /vagrant/OpenDSA-LTI ]; then
#   sudo-pw git clone https://github.com/OpenDSA/OpenDSA-LTI.git /vagrant/OpenDSA-LTI
# fi

cd /vagrant
git checkout RailsConfigIntg

# add profile to bash_profile as recommended by rvm
cd ~/
touch ~/.bash_profile
echo "source ~/.profile" >> ~/.bash_profile

# Get mpapis' pubkey per https://rvm.io/rvm/security
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -L https://get.rvm.io | bash -s stable --ruby=2.3.0
source ~/.rvm/scripts/rvm

# reload profile to set paths for gem and rvm commands
source ~/.bash_profile

## GEMS
sudo-pw gem install bundler

cd /vagrant
sudo-pw bundle install

# Create link to OpenDSA
# ln -s /vagrant/OpenDSA /vagrant/OpenDSA-LTI/public

# bash /vagrant/runservers.sh
rails server -b 0.0.0.0 -p 3000

