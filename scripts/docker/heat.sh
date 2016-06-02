#!/bin/bash

cd /tmp
git clone -b stable/liberty https://github.com/openstack/heat.git
cd heat/contrib/heat_docker/
sudo pip install -r requirements.txt
sudo mkdir -p /var/lib/heat
sudo cp -r heat_docker/ /var/lib/heat
sudo chown -R vagrant:vagrant /var/lib/heat
sudo sed -i 's|rpc_backend = rabbit|rpc_backend = rabbit \
plugin_dirs = /var/lib/heat|g' /etc/heat/heat.conf
sudo chown -R vagrant:vagrant /var/lib/heat

/vagrant/scripts/minimize/clean.sh

