#!/bin/bash

sudo sh -c "echo 'deb http://download.virtualbox.org/virtualbox/debian '$(lsb_release -cs)' contrib non-free' > /etc/apt/sources.list.d/virtualbox.list" 
wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | sudo apt-key add -
sudo apt-get update -y
sudo apt-get install -y virtualbox-5.0

wget https://releases.hashicorp.com/vagrant/1.7.4/vagrant_1.7.4_x86_64.deb
sudo dpkg -i vagrant_1.7.4_x86_64.deb

IAM=`whoami`
sudo adduser $IAM vboxusers

cd ../config-sudoers
sudo sh -c ./config-sudoers-linux-ubuntu.sh

cd ../install-plugin
./install-plugin-vbguest.sh
./install-plugin-cachier.sh