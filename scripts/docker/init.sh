#!/bin/bash

curl -s 'https://sks-keyservers.net/pks/lookup?op=get&search=0xee6d536cf7dc86e2d7d56f59a178ac6c6238f52e' | sudo apt-key add --import
sudo apt-get update && sudo apt-get install -qqy apt-transport-https
sudo apt-get install -qqy linux-image-extra-virtual
echo "deb https://packages.docker.com/1.11/apt/repo ubuntu-trusty main" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update && sudo apt-get install -qqy docker-engine
sudo usermod -a -G docker vagrant

sudo mkdir -p /var/lib/registry
sudo mkdir -p /etc/docker/registry
sudo cp /vagrant/scripts/docker/config.yml /etc/docker/registry/config.yml

sudo chown -R :docker /var/lib/registry/
sudo chown -R :docker /etc/docker/registry/

# sudo apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
# sudo bash -c "echo 'deb https://apt.dockerproject.org/repo ubuntu-trusty main' > /etc/apt/sources.list.d/docker.list"

# sudo apt-get -qqy update
# sudo apt-get install -qqy docker-engine

# sudo usermod -aG docker vagrant
# newgrp docker
