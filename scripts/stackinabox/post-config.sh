#!/bin/bash

# set release branch to retrieve from git
MTU=${2:-1500}

iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE

sudo ip link set dev enp0s3 mtu $MTU
sudo ip link set dev enp0s8 mtu $MTU

source /home/vagrant/demo-openrc.sh labstack
echo "recreating router"
neutron router-gateway-clear router1
neutron router-interface-delete router1 private-subnet
neutron router-delete router1

neutron router-create demorouter
neutron router-gateway-set demorouter public
neutron router-interface-add demorouter private-subnet


# add DNS nameserver entries to "private" subnet in 'demo' tenant
echo "Updating dns_nameservers on the 'demo' tenant's private subnet"
neutron subnet-update private-subnet --dns_nameservers list=true 8.8.8.8 8.8.4.4
# allow ssh access to instances deployed with the 'default' security group
openstack security group rule create default --proto tcp --dst-port 22

# Heat needs to launch instances with a keypair, lets generate a 'default' keypair
echo "Generating new keypair for the 'demo' tenant in /home/vagrant"
openstack keypair create demo_key > /tmp/demo_key.priv
sudo mv /tmp/demo_key.priv /home/vagrant
sudo chmod 400 /home/vagrant/demo_key.priv
sudo chown vagrant:vagrant /home/vagrant/demo_key.priv

# source openrc with admin privledges
source /home/vagrant/admin-openrc.sh labstack
openstack project delete invisible_to_admin

# add lxd compatible images to openstack
echo "Adding LXD compatible images to OpenStack"

cd /vagrant/lxc-cloud-images
chmod 755 import-images.sh
./import-images.sh
cat << EOF
This is your host IP address: 192.168.27.100
Horizon is now available at http://192.168.27.100/dashboard
Keystone is serving at http://192.168.27.100:5000/
The default users are: admin and demo
The password: labstack
Key pair is at /home/vagrant/demo_key.priv
EOF
