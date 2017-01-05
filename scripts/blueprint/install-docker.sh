#!/bin/bash

apt-get update
apt-get install -qqy apt-transport-https ca-certificates
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

touch /etc/apt/sources.list.d/docker.list
echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get purge lxc-docker

apt-get update
apt-get install -qqy linux-image-extra-$(uname -r) linux-image-extra-virtual

apt-get update
apt-get install -qqy docker-engine

docker swarm join \
    --token SWMTKN-1-4qhfi2ca5tjflqq4eby2qae1ym9wfq6m95txzxvtpb0meg8eq1-cgqen98kgbrfx9ocmmjh4398s \
    10.0.0.12:2377