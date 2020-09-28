make -f Makefile venv
mkdir -p /home/deploy/OpenDSA
ls
ls .pyVenv
cp -r .pyVenv/ /home/deploy/OpenDSA/
. .pyVenv/bin/activate
echo "cd /home/deploy/OpenDSA" >> /root/.bashrc
echo ". .pyVenv/bin/activate" >> /root/.bashrc
echo "cd /opendsa-lti" >> /root/.bashrc