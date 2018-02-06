# OpenDSA content server
cd /vagrant/OpenDSA
./WebServer &

sleep 2
# OpenDSA-LTI server
cd /vagrant/OpenDSA-LTI
bundle exec rake jobs:work &

sleep 2
# OpenDSA-LTI server
cd /vagrant/OpenDSA-LTI
bundle exec thin start --ssl --ssl-key-file server.key --ssl-cert-file server.crt -p 9292
