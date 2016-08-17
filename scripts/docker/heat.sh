#!/bin/bash

# set release branch to retrieve from git
RELEASE_BRANCH=${1:-master}

cd /tmp
git clone -b $RELEASE_BRANCH https://github.com/openstack/heat.git
cd heat/contrib/heat_docker/
sudo pip install -r requirements.txt
sudo mkdir -p /var/lib/heat
sudo cp -r heat_docker/ /var/lib/heat
sudo chown -R vagrant:vagrant /var/lib/heat
sudo sed -i 's|rpc_backend = rabbit|rpc_backend = rabbit \
plugin_dirs = /var/lib/heat|g' /etc/heat/heat.conf
sudo chown -R vagrant:vagrant /var/lib/heat

source /home/vagrant/admin-openrc.sh labstack
nova flavor-key m1.tiny set lxd_docker_allowed=true
nova flavor-key m1.small set lxd_docker_allowed=true
nova flavor-key m1.medium set lxd_docker_allowed=true
nova flavor-key m1.large set lxd_docker_allowed=true
nova flavor-key m1.xlarge set lxd_docker_allowed=true