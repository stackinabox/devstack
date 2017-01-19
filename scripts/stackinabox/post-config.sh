#!/bin/bash

# exit on error
set -e

# set release branch to retrieve from git
MTU=${2:-1500}

sudo iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE

# sudo ip link set dev enp0s3 mtu $MTU
# sudo ip link set dev enp0s8 mtu $MTU
# sudo ip link set dev enp0s9 mtu 1450

source /home/vagrant/demo-openrc.sh labstack
# echo "recreating router"
# neutron router-gateway-clear router1
# neutron router-interface-delete router1 private-subnet
# neutron router-delete router1

# neutron router-create demorouter
# neutron router-gateway-set demorouter public
# neutron router-interface-add demorouter private-subnet


# add DNS nameserver entries to "private" subnet in 'demo' tenant
echo "Updating dns_nameservers on the 'demo' tenant's private subnet"
neutron subnet-update private-subnet --dns_nameservers list=true 8.8.8.8 8.8.4.4
# allow ssh access to instances deployed with the 'default' security group
openstack security group rule create default --protocol tcp --dst-port 22:22 --src-ip 0.0.0.0/0
# allow pinging from all IP addresses
openstack security group rule create default --protocol icmp --src-ip 0.0.0.0/0
# all UDP access to port 53 for DNS
openstack security group rule create default --protocol udp --dst-port 53:53 --src-ip 0.0.0.0/0

source /home/vagrant/admin-openrc.sh labstack

# delete default flavors (m1.tiny, m1.small, m1.medium, m1.large, m1.xlarge)
nova flavor-delete m1.tiny
nova flavor-delete m1.small
nova flavor-delete m1.medium
nova flavor-delete m1.large
nova flavor-delete m1.xlarge
nova flavor-delete ds1G
nova flavor-delete ds2G
nova flavor-delete ds4G
nova flavor-delete ds512M
nova flavor-delete cirros256

# create basic flavors to be used with lxd iamges
nova flavor-create m1.tiny 001 512 5 1
nova flavor-key m1.tiny set 'lxd:docker_allowed'='True'
nova flavor-create m1.small 002 1024 10 1
nova flavor-key m1.small set 'lxd:docker_allowed'='True'
nova flavor-create m1.medium 003 2048 20 2
nova flavor-key m1.medium set 'lxd:docker_allowed'='True'
nova flavor-create m1.large 004 4096 40 4
nova flavor-key m1.large set 'lxd:docker_allowed'='True'
nova flavor-create m1.xlarge 005 8192 40 4
nova flavor-key m1.xlarge set 'lxd:docker_allowed'='True'

# delete automatically added images by nova-lxd
openstack image delete cirros-0.3.4-x86_64-lxd
openstack image delete ubuntu-16.04-lxd-root

# switch to admin openstack user
source /home/vagrant/admin-openrc.sh labstack

# delete unused "alt_demo" project
openstack project delete alt_demo

# switch back to demo openstack user
source /home/vagrant/demo-openrc.sh labstack

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

# setup bluebox theme
cp /vagrant/scripts/bluebox-theme/logo.png /opt/stack/horizon/static/dashboard/img/logo.png
cp /vagrant/scripts/bluebox-theme/logo-splash.png /opt/stack/horizon/static/dashboard/img/logo-splash.png
# haven't been able to find this file yet
#mv /vagrant/scripts/bluebox-theme/bluebox.ico /opt/stack/horizon/static/dashboard/img/favicon.ico

cat << EOF
This is your host IP address: 192.168.27.100
Horizon is now available at http://192.168.27.100/dashboard
Keystone is serving at http://192.168.27.100/identity
The default users are: admin and demo
The password: labstack
Key pair is at /home/vagrant/demo_key.priv
EOF
