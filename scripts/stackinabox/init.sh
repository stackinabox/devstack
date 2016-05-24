#!/bin/bash

# set release branch to retrieve from git
RELEASE_BRANCH=${1:-master}
MTU=${2:-1500}

echo ""
echo ""
echo "###############################################################################"
echo "## Installing OpenStack (Devstack)                                           ##"
echo "## using RELEASE_BRANCH=\"${RELEASE_BRANCH}\"                                ##"
echo "###############################################################################"
echo ""
echo ""

# Disable interactive options when installing with apt-get
export DEBIAN_FRONTEND=noninteractive

echo export LC_ALL=en_US.UTF-8 >> ~/.bash_profile
echo export LANG=en_US.UTF-8 >> ~/.bash_profile

# Don't automatically install recommended or suggested packages
sudo mkdir -p /etc/apt/apt.config.d
sudo echo 'APT::Install-Recommends "0";' | sudo tee --append /etc/apt/apt.config.d/99local > /dev/null
sudo echo 'APT::Install-Suggests "0";' | sudo tee --append /etc/apt/apt.config.d/99local > /dev/null

# Add software repository
which add-apt-repository || (sudo apt-get -qqy update ; sudo apt-get -qqy install software-properties-common)
#sudo add-apt-repository ppa:ubuntu-cloud-archive/liberty-staging
sudo add-apt-repository cloud-archive:liberty
# sudo add-apt-repository ppa:ubuntu-lxc/stable
# sudo add-apt-repository ppa:ubuntu-lxc/lxcfs-stable
# sudo add-apt-repository ppa:ubuntu-lxc/cgmanager-stable
# sudo add-apt-repository ppa:ubuntu-lxc/lxd-stable
# comment above ppa and uncomment below to get development lxd builds
sudo add-apt-repository ppa:ubuntu-lxc/lxd-git-master
sudo apt-get -qqy update
sudo apt-get -qqy install python-pip python-dev git libvirt-bin #cgroup-lite cgmanager libpam-cgm
sudo pip install -U pbr
sudo pip install -U pip
#sudo pip install -U requests==2.5.3
sudo pip install -U requests==2.8.1

# for barbican support
sudo pip install 'uwsgi'
sudo chmod +x /usr/local/bin/uwsgi

sudo update-alternatives --install /bin/sh sh /bin/bash 100

# We need swap space to do any sort of scale testing with the Vagrant config.
# Without this, we quickly run out of RAM and the kernel starts whacking things.
sudo rm -f /swapfile1
sudo dd if=/dev/zero of=/swapfile1 bs=1024 count=8388608
sudo chown root:root /swapfile1
sudo chmod 0600 /swapfile1
sudo mkswap /swapfile1
sudo swapon /swapfile1

# Disable firewall (this is not production)
sudo ufw disable

# To permit IP packets pass through different networks,
# the network card should be configured with routing capability.
sudo echo "net.ipv4.ip_forward = 1" | sudo tee --append /etc/sysctl.conf > /dev/null
sudo echo "net.ipv4.conf.all.rp_filter=0" | sudo tee --append /etc/sysctl.conf > /dev/null
sudo echo "net.ipv4.conf.default.rp_filter=0" | sudo tee --append /etc/sysctl.conf > /dev/null
sudo echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee --append /etc/sysctl.conf > /dev/null
sudo echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee --append /etc/sysctl.conf > /dev/null
sudo echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee --append /etc/sysctl.conf > /dev/null
sudo sysctl -p

# allow OpenStack nodes to route packets out through NATed network on HOST (this is the vagrant managed nic)
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Update host configuration
sudo bash -c "echo 'openstack.stackinabox.io' > /etc/hostname"
#export eth1=`ifconfig eth1 | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`
sudo bash -c 'cat > /etc/hosts' <<EOF
127.0.0.1         localhost.localdomain     localhost openstack.stackinabox.io openstack
192.168.27.100    openstack.stackinabox.io  openstack

EOF

# speed up DNS resolution
sudo bash -c 'cat > /etc/dhcp/dhclient.conf' <<EOF
timeout 30;
retry 10;
reboot 0;
select-timeout 0;
initial-interval 1;
backoff-cutoff 2;
link-timeout 10;
interface "eth0"
{
  supersede host-name "openstack.stackinabox.io";
  supersede domain-name "stackinabox.io";
  prepend domain-name-servers 192.168.27.1, 8.8.8.8, 8.8.4.4;
  request subnet-mask,
          broadcast-address,
          routers,
          domain-name,
          domain-name-servers,
          host-name;
  require routers,
          subnet-mask,
          domain-name-servers;
}
EOF

# Restart networking
sudo /etc/init.d/networking restart

# enable cgroup memory limits
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="cgroup_enable=memory swapaccount=1 /g' /etc/default/grub
sudo sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1 /g' /etc/default/grub
sudo update-grub

# Clone devstack repo
echo "Cloning DevStack repo from branch \"${RELEASE_BRANCH}\""
sudo mkdir -p /opt/stack
sudo chown -R vagrant:vagrant /opt/stack
git clone https://git.openstack.org/openstack-dev/devstack.git /opt/stack/devstack -b "${RELEASE_BRANCH}"

# add local.conf to /opt/devstack folder
cp /vagrant/scripts/stackinabox/local.conf /opt/stack/devstack/

# update RELEASE_BRANCH variable in local.conf to match existing 
# (use '@' as delim in sed b/c $RELEASE_BRANCH may contain '/')
sed -i "s@RELEASE_BRANCH=@RELEASE_BRANCH=$RELEASE_BRANCH@" /opt/stack/devstack/local.conf

# don't assign IP to eth2 yet
sudo ifconfig eth2 0.0.0.0
sudo ifconfig eth2 promisc
sudo ip link set dev eth2 up

# gentelmen start your engines
echo "Installing DevStack"
cd /opt/stack/devstack
./stack.sh
echo "Finished installing DevStack"

# bridge eth2 to ovs for our public network
sudo ovs-vsctl add-port br-ex eth2
sudo ifconfig br-ex promisc up

# assign ip from public network to bridge (br-ex)
sudo bash -c 'cat >> /etc/network/interfaces' <<'EOF'

auto eth2
iface eth2 inet manual
    address 0.0.0.0
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

# Install NTP
sudo apt-get install -y ntp

# stop ntp service so we can set the pool to use
sudo service ntp stop

# Set ntp.ubuntu.com as the direct source of time.
sudo ntpdate us.pool.ntp.org

# restart the NTP service
sudo service ntp restart

# Configure MTU on VM interfaces. Also requires manually configuring the same MTU on
# the equivalent 'vboxnet' interfaces on the host. i.e. sudo ip link set dev vboxnet0 mtu $MTU
sudo ip link set dev eth1 mtu $MTU
sudo ip link set dev eth2 mtu $MTU

# Restart networking
sudo /etc/init.d/networking restart

# source openrc for openstack connection variables
source /opt/stack/devstack/openrc demo demo

# add DNS nameserver entries to "private" subnet in 'demo' tenant
echo "Updating dns_nameservers on the 'demo' tenant's private subnet"
neutron subnet-update private-subnet --dns_nameservers list=true 8.8.8.8 8.8.4.4

# Heat needs to launch instances with a keypair, lets generate a 'default' keypair
echo "Generating new keypair for the 'demo' tenant in /home/vagrant"
nova keypair-add demo_key > ~/demo_key.priv
chmod 400 ~/demo_key.priv

# source openrc with admin privledges
source /opt/stack/devstack/openrc admin admin

# allow ssh access to instances deployed with the 'default' security group
nova secgroup-add-group-rule default default tcp 22 22

# delete the invisible_to_admin tenant (not needed)
keystone tenant-delete invisible_to_admin

# add lxd compatible images to openstack
echo "Adding LXD compatible images to OpenStack"

mkdir -p /vagrant/images
cd /vagrant/images
#rm -rf ./*

#wget -nv https://github.com/tpouyer/lxc-cloud-images/releases/download/stable%2Fliberty/lxc-cloud-images.tar.xz
#tar -xf lxc-cloud-images.tar.xz

chmod 755 import-images.sh
./import-images.sh

# give vagrant user lxd permissions
sudo chown -R lxd:lxd /var/lib/lxd
sudo chmod -R go+rwxt /var/lib/lxd
sudo usermod -a -G lxd vagrant
newgrp lxd

# add devstack to init.d so it will automatically start/stop with the machine
cp /vagrant/scripts/stackinabox/stack-noscreenrc /opt/stack/devstack/stack-noscreenrc
chmod 755 /opt/stack/devstack/stack-noscreenrc
sudo cp /vagrant/scripts/stackinabox/devstack2 /etc/init.d/devstack
sudo chmod +x /etc/init.d/devstack
sudo update-rc.d devstack start 98 2 3 4 5 . stop 02 0 1 6 .

# install 'shellinabox' to make using this image on windows easier
# shellinabox will be available at http://192.168.27.100:4200
# sudo apt-get install -y shellinabox
# sudo sed -i 's/--no-beep/--no-beep --disable-ssl/g' /etc/default/shellinabox
# sudo /etc/init.d/shellinabox restart

# wait for openstack to startup
sleep 60

# install java (for use with udclient)
sudo apt-get install -qqy default-jre
sudo touch /etc/profile.d/java_home.sh
sudo bash -c 'cat >> /etc/profile.d/java_home.sh' <<'EOF'
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/jre
EOF
sudo chmod 755 /etc/profile.d/java_home.sh

# clean up after ourselves
/vagrant/scripts/minimize/clean.sh 

sudo btrfs quota enable /var/lib/lxd

# restart
#sudo shutdown -P now
