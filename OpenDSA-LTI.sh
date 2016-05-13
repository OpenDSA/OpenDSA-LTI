#!/usr/bin/env bash

# Function to issue sudo command with password
function sudo-pw {
    echo "vagrant" | sudo -S $@
}

function install {
    echo installing $1
    shift
    apt-get -y install "$@" >/dev/null 2>&1
}

# Start configuration
# sudo-pw apt-get -y update

echo updating package information
apt-add-repository -y ppa:brightbox/ruby-ng >/dev/null 2>&1
apt-get -y update >/dev/null 2>&1

install 'development tools' build-essential

install Ruby ruby2.3 ruby2.3-dev
update-alternatives --set ruby /usr/bin/ruby2.3 >/dev/null 2>&1
update-alternatives --set gem /usr/bin/gem2.3 >/dev/null 2>&1

echo installing Bundler
gem install bundler -N >/dev/null 2>&1

install Git git
install SQLite sqlite3 libsqlite3-dev
install memcached memcached
install Redis redis-server
install RabbitMQ rabbitmq-server

# install PostgreSQL postgresql postgresql-contrib libpq-dev
# sudo -u postgres createuser --superuser vagrant
# sudo -u postgres createdb -O vagrant activerecord_unittest
# sudo -u postgres createdb -O vagrant activerecord_unittest2

install 'Nokogiri dependencies' libxml2 libxml2-dev libxslt1-dev
install 'ExecJS runtime' nodejs

# Needed for docs generation.
update-locale LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8


sudo-pw apt-get -y install dkms
sudo-pw apt-get -y install curl
sudo-pw apt-get -y install libxml2-dev libxslt-dev
sudo-pw apt-get -y install git
sudo-pw apt-get -y install libpq-dev
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
sudo-pw apt-get -y install default-jre

# sudo-pw apt-get -y update

sudo-pw apt-get -y install python-sphinx
sudo-pw curl -sL https://deb.nodesource.com/setup | sudo bash -
sudo-pw apt-get -y install uglifyjs
sudo-pw apt-get -y install uglifycss
sudo-pw ln -s /usr/bin/nodejs /usr/bin/node
sudo-pw ln -s /usr/bin/nodejs /usr/sbin/node
sudo-pw npm install -g jshint
sudo-pw npm install -g csslint

# Clone OpenDSA
if [ ! -d /vagrant/public/OpenDSA ]; then
  sudo-pw git clone https://github.com/OpenDSA/OpenDSA.git /vagrant/public/OpenDSA
fi

cd /vagrant/public/OpenDSA/
sudo-pw pip install -r requirements.txt --upgrade
make pull

cd /vagrant
git checkout RailsConfigIntg
sudo-pw bundle install

# Create link to OpenDSA
# ln -s /vagrant/OpenDSA /vagrant/OpenDSA-LTI/public

# bash /vagrant/runservers.sh
rails server -b 0.0.0.0 -p 3000


