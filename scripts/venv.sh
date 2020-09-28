make -f Makefile clean-venv venv
mkdir -p /home/deploy/OpenDSA
cp -r .pyVenv/ /home/deploy/OpenDSA/
. .pyVenv/bin/activate
echo "cd /home/deploy/OpenDSA" >> /root/.bashrc
echo ". .pyVenv/bin/activate" >> /root/.bashrc
echo "cd /opendsa-lti" >> /root/.bashrc