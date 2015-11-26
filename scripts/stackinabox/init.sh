#!/bin/bash

# set release branch to retrieve from git
RELEASE_BRANCH=${1:-"stable/liberty"}

echo ""
echo ""
echo "###############################################################################"
echo "## Installing OpenStack (Devstack)                                           ##"
echo "## using RELEASE_BRANCH=$RELEASE_BRANCH                                      ##"
echo "###############################################################################"
echo ""
echo ""

# Add software repository
apt-get update -y
apt-get install -y python-software-properties software-properties-common
add-apt-repository ppa:ubuntu-cloud-archive/liberty-staging
add-apt-repository ppa:ubuntu-lxc/lxd-stable
# comment above ppa and uncomment below to get development lxd builds
#add-apt-repository ppa:ubuntu-lxc/lxd-git-master

# Update repositories
apt-get update -y

# Disable interactive options when installing with apt-get
export DEBIAN_FRONTEND=noninteractive

# Don't automatically install recommended or suggested packages
mkdir -p /etc/apt/apt.config.d
echo 'APT::Install-Recommends "0";' >> /etc/apt/apt.config.d/99local
echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.config.d/99local

# Disable firewall (this is not production)
ufw disable

# Update host configuration
hostname "stackinabox"
echo "stackinabox" > /etc/hostname
cat > /etc/hosts << EOF
127.0.1.1       stackinabox
127.0.0.1       localhost localdomain

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
EOF

# Restart networking
#/etc/init.d/networking restart

# To permit IP packets pass through different networks,
# the network card should be configured with routing capability.
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.rp_filter=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.rp_filter=0" >> /etc/sysctl.conf
sysctl -p

# allow OpenStack nodes to route packets out through NATed network on HOST (this is the vagrant managed nic)
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Setup DNS name servers
mkdir -p /etc/resolvconf/resolv.conf.d/
echo "nameserver 8.8.4.4" >> /etc/resolvconf/resolv.conf.d/base
echo "nameserver 8.8.8.8" >> /etc/resolvconf/resolv.conf.d/base
echo "nameserver 208.67.220.220" >> /etc/resolvconf/resolv.conf.d/base
echo "rotate true" >> /etc/resolvconf/resolv.conf.d/base
echo "options attempts:1 timeout:4" >> /etc/resolvconf/resolv.conf.d/base

# speed up DNS resolution
sed -i 's/#prepend domain-name-servers 127.0.0.1;/prepend domain-name-servers 8.8.4.4, 8.8.8.8, 208.67.220.220;/g' /etc/dhcp/dhclient.conf
sed -i 's/#timeout 60;/timeout 10;/g' /etc/dhcp/dhclient.conf
sed -i 's/#retry 60;/retry 10;/g' /etc/dhcp/dhclient.conf
sed -i 's/#reboot 10;/reboot 0;/g' /etc/dhcp/dhclient.conf
sed -i 's/#select-timeout 5;/select-timeout 0;/g' /etc/dhcp/dhclient.conf
sed -i 's/#initial-interval 2;/initial-interval 1;/g' /etc/dhcp/dhclient.conf
sed -i 's/#reject 192.33.137.209;/link-timeout 10;/g' /etc/dhcp/dhclient.conf
sed -i 's/#media "-link0 -link1 -link2", "link0 link1";/backoff-cutoff 2;/g' /etc/dhcp/dhclient.conf

# Restart networking
/etc/init.d/networking restart

# Install NTP
apt-get install -y ntp

# Set ntp.ubuntu.com as the direct source of time.
# Also provide local time source in case of network interruption.
sed -i 's/server ntp.ubuntu.com/ \
server ntp.ubuntu.com \
server 127.127.1.0 \
fudge 127.127.1.0 stratum 10/g' /etc/ntp.conf

# restart the NTP service
service ntp restart

# install some prerequisites
apt-get install -y git

# Clone devstack repo
echo "Cloning DevStack repo from branch '${RELEASE_BRANCH}'"
mkdir -p /opt/stack
cd /opt/stack
git clone https://git.openstack.org/openstack-dev/devstack.git
cd devstack
git checkout $RELEASE_BRANCH
sed -i 's/git:/https:/g' stackrc

# add local.conf to /opt/devstack folder
cp /vagrant/scripts/stackinabox/local.conf /opt/stack/devstack/

# update RELEASE_BRANCH variable in local.conf to match existing
sed -i 's/RELEASE_BRANCH=/RELEASE_BRANCH=${RELEASE_BRANCH}/g' /etc/default/shellinabox

# make vagrant user owner of /opt/stack
chown -R vagrant:vagrant /opt/stack

# don't assign IP to eth2 yet
ifconfig eth2 0.0.0.0
ifconfig eth2 promisc
ip link set dev eth2 up

# gentelmen start your engines
echo "Installing DevStack"
cd /opt/stack/devstack
su -c ./stack.sh -s /bin/sh vagrant
echo "Finished installing DevStack"

# bridge eth2 to ovs for our public network
ovs-vsctl add-port br-ex eth2
ifconfig br-ex promisc up

# assign ip from public network to bridge (br-ex)
cat >> /etc/network/interfaces <<'EOF'
auto eth2
iface eth2 inet manual
    up ifconfig $IFACE 0.0.0.0 up
    up ip link set $IFACE promisc on
    down ip link set $IFACE promisc off
    down ifconfig $IFACE down

auto br-ex
iface br-ex inet static
    address 172.24.4.2
    netmask 255.255.255.0
    up ip link set $IFACE promisc on
    down ip link set $IFACE promisc off
EOF

# Restart networking
/etc/init.d/networking restart

# source openrc for openstack connection variables
source /opt/stack/devstack/openrc

# add DNS nameserver entries to "private" subnet in 'demo' tenant
echo "Updating dns_nameservers on the 'demo' tenant's private subnet"
neutron subnet-update private-subnet --dns_nameservers list=true 10.0.0.1 8.8.4.4 8.8.8.8 208.67.220.220

# Heat needs to launch instances with a keypair, lets generate a 'default' keypair
echo "Generating new keypair for the 'demo' tenant in /home/vagrant"
nova keypair-add demo_key > /home/vagrant/demo_key.priv
chown vagrant:vagrant /home/vagrant/demo_key.priv

# copy private key to shared '/vagrant' folder
cp /home/vagrant/demo_key.priv /vagrant/
chmod 600 /vagrant/demo_key.priv

# allow ssh access to instances deployed with the 'default' security group
nova secgroup-add-group-rule default default tcp 22 22

# source openrc with admin privledges
source /opt/stack/devstack/openrc admin admin

# add lxd compatible images to openstack
echo "Adding LXD compatible images to OpenStack"

mkdir -p /vagrant/scripts/lxd/images
cd /vagrant/scripts/lxd/images

wget https://github.com/tpouyer/lxc-cloud-images/releases/download/stable%2Fliberty/lxc-cloud-images.tar.gz
tar -xvzf lxc-cloud-images.tar.gz

chmod 755 import-images.sh
./import-images.sh

# give vagrant user lxd permissions
chown -R lxd:lxd /var/lib/lxd
usermod -a -G lxd vagrant

# add devstack to init.d so it will automatically start/stop with the machine
cp /vagrant/scripts/stackinabox/devstack /etc/init.d/devstack
chmod +x /etc/init.d/devstack
update-rc.d devstack defaults 98 02

# install 'shellinabox' to make using this image on windows easier
# shellinabox will be available at http://192.168.27.100:4200
apt-get install -y shellinabox
sed -i 's/--no-beep/--no-beep --disable-ssl/g' /etc/default/shellinabox
/etc/init.d/shellinabox restart

# wait for openstack to startup
sleep 60

# clean up after ourselves
/vagrant/scripts/stackinabox/clean.sh

# restart OS so the vagrant user will have lxd rights upon startup
shutdown -r now