#!/bin/bash

# exit on error
set -e

# set release branch to retrieve from git
MTU=${2:-1500}

sudo iptables -t nat -A POSTROUTING -o ens32 -j MASQUERADE

# sudo ip link set dev ens32 mtu $MTU
# sudo ip link set dev ens33 mtu $MTU
# sudo ip link set dev ens34 mtu 1450

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

# setup demo user on this system
sudo useradd -m -p $(perl -e 'printf("%s\n", crypt("labstack", "password"))') -s /bin/bash demo
sudo usermod -aG docker demo
sudo usermod -aG sudo demo
sudo cp /home/vagrant/demo_key.priv /home/demo/demo_key.priv
sudo chown demo:demo /home/demo/demo_key.priv

sudo cp /home/vagrant/admin-openrc.sh /home/demo/admin-openrc.sh
sudo chown demo:demo /home/demo/admin-openrc.sh

sudo cp /home/vagrant/demo-openrc.sh /home/demo/demo-openrc.sh
sudo chown demo:demo /home/demo/demo-openrc.sh

# turn off ssh KnowHostsFile and StrictHostChecking 
# for this machine (demo purposes only, don't ever do in production)
sudo bash -c 'cat >> /etc/ssh/ssh_config' <<'EOF'
Host *
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null
EOF

# change "Listen 80' to 'Listen 8888' in /etc/apache2/ports.conf
sudo sed -i 's/Listen 80/Listen 8888/g' /etc/apache2/ports.conf

# change 'VirtualHost *:80' to 'VirtualHost *:8888' in /etc/apache2/sites-enabled/horizon.conf
sudo sed -i 's/:80/:8888/g' /etc/apache2/sites-enabled/horizon.conf

sudo systemctl reload apache2

# install nginx
sudo apt-get install -qqy nginx

# disable the default vhost site
sudo rm -f /etc/nginx/sites-enabled/default

# update /etc/nginx/nginx.conf
# change 'sendfile on;' to 'sendfile off;'
sudo sed -i 's/sendfile on;/sendfile off;/g' /etc/nginx/nginx.conf

# add 'underscores_in_headers on;' 
sudo sed -i 's/# server_tokens off;/underscores_in_headers on;/g' /etc/nginx/nginx.conf

# setup openstack.stackinabox.io forwarding
sudo bash -c 'cat > /etc/nginx/sites-available/openstack.conf' <<'EOF'
server {
        server_name openstack.stackinabox.io 192.168.27.100;

        gzip_types text/plain text/css application/json application/x-javascript
                   text/xml application/xml application/xml+rss text/javascript;

        location / {

                proxy_redirect off;
                proxy_pass http://192.168.27.100:8888/;
                proxy_set_header Host $host:$server_port;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
        }
}
EOF
sudo ln -s /etc/nginx/sites-available/openstack.conf /etc/nginx/sites-enabled/openstack.conf

# setup ucd.stackinabox.io forwarding
sudo bash -c 'cat > /etc/nginx/sites-available/ucd.conf' <<'EOF'
server {
        server_name ucd.stackinabox.io;

        gzip_types text/plain text/css application/json application/x-javascript
                   text/xml application/xml application/xml+rss text/javascript;

        location / {

                proxy_redirect off;
                proxy_pass http://ucd.stackinabox.io:8080/;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
        }
}
EOF
sudo ln -s /etc/nginx/sites-available/ucd.conf /etc/nginx/sites-enabled/ucd.conf

# setup shell.stackinabox.io forwarding
sudo bash -c 'cat > /etc/nginx/sites-available/shell.conf' <<'EOF'
server {
        server_name shell.stackinabox.io;

        gzip_types text/plain text/css application/json application/x-javascript
                   text/xml application/xml application/xml+rss text/javascript;

        location / {

                proxy_redirect off;
                proxy_pass http://shell.stackinabox.io:4200/;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
        }
}
EOF
sudo ln -s /etc/nginx/sites-available/shell.conf /etc/nginx/sites-enabled/shell.conf

# setup designer.stackinabox.io forwarding
sudo bash -c 'cat > /etc/nginx/sites-available/designer.conf' <<'EOF'
server {
        server_name designer.stackinabox.io;

        gzip_types text/plain text/css application/json application/x-javascript
                   text/xml application/xml application/xml+rss text/javascript;

        location / {
                return 302 /landscaper/;
        }

        location /landscaper/ {

                proxy_redirect off;
                proxy_pass http://designer.stackinabox.io:9080/landscaper/;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
        }
}
EOF
sudo ln -s /etc/nginx/sites-available/designer.conf /etc/nginx/sites-enabled/designer.conf

# reload nginx
sudo systemctl reload nginx

cat << 'EOF'

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Horizon is now available at http://openstack.stackinabox.io
Keystone is serving at http://192.168.27.100:8888/identity/v3
The default users are: admin and demo
The password: labstack
Key pair is at /home/vagrant/demo_key.priv

++++++ Access the console from your shell:
ssh demo@192.168.27.100
password: labstack

++++++ Access the console from your web browser at:
http://shell.stackinabox.io
username: demo
password: labstack

EOF
