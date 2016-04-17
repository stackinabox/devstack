#!/bin/bash

sudo apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
sudo bash -c "echo 'deb https://apt.dockerproject.org/repo ubuntu-trusty main' > /etc/apt/sources.list.d/docker.list"

sudo apt-get -qqy update
sudo apt-get install -qqy docker-engine

sudo usermod -aG docker vagrant
newgrp docker
