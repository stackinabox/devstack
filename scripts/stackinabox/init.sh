#!/bin/bash

# exit on error
#set -e

# set release branch to retrieve from git
RELEASE_BRANCH=${1:-master}
MTU=${2:-1550}

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

echo export LC_ALL=C.UTF-8 >> ~/.bash_profile
echo export LANG=C.UTF-8 >> ~/.bash_profile

sudo bash -c 'cat > /etc/apt/apt.conf.d/01lean' <<'EOF'
APT::Install-Suggests "0";
APT::Install-Recommends "0";
APT::AutoRemove::SuggestsImportant "false";
APT::AutoRemove::RecommendsImportant "false";
EOF

echo Updating...
sudo dpkg --configure -a
sleep 10
sudo apt-get -qqy update
sudo apt-get install -qqy linux-headers-$(uname -r) \
  linux-headers-generic \
  linux-image-extra-$(uname -r) \
  linux-image-extra-virtual \
  libncurses5-dev \
  libncursesw5-dev

sudo apt-get -y update
sudo apt-get -qqy install zfsutils-linux git

echo "Creating ZFS for lxd"
sudo apt-get -qqy purge lxd
sudo rm -rf /var/lib/lxd/*
sudo zpool create -m /var/lib/lxd -f lxd sdb
sudo zpool set feature@lz4_compress=enabled lxd
sudo zfs set compression=lz4 lxd
sudo touch /etc/init/zpool-import.conf
sudo sed -i 's/modprobe zfs zfs_autoimport_disable=1/modprobe zfs zfs_autoimport_disable=0/g' /etc/init/zpool-import.conf
sudo sed -i 's/# By default this script does nothing./zfs mount -a/g' /etc/rc.local
sudo chown -R :lxd /var/lib/lxd

echo "Creating ZFS for docker"
sudo zpool create -m /var/lib/docker -f docker sdc
sudo zpool set feature@lz4_compress=enabled docker
sudo zfs set compression=lz4 docker
sudo touch /etc/init/zpool-import.conf
sudo chown -R :lxd /var/lib/lxd

echo "Install LXD and initialize with ZFS storage-pool 'lxd' for backend"
sudo apt-get install -y lxd lxd-client aufs-tools
sudo lxd init --auto --storage-backend zfs --storage-pool lxd
sudo chown -R :lxd /var/lib/lxd

# flip the module parameters to enable user namespace mounts for fuse and/or ext4 within lxd containers
echo Y | sudo tee /sys/module/fuse/parameters/userns_mounts
echo Y | sudo tee /sys/module/ext4/parameters/userns_mounts

sudo apt-get install -y python-pip python-setuptools e2fsprogs haproxy
sudo -H pip install --upgrade pip
sudo -H easy_install pip
sudo -H pip install -U os-testr pbr
# sudo apt-get install -y python-setuptools

echo "configuring swap..."
# We need swap space to do any sort of scale testing with the Vagrant config.
# Without this, we quickly run out of RAM and the kernel starts whacking things.
sudo rm -f /swapfile
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo echo "vm.swappiness = 10" | sudo tee --append /etc/sysctl.conf > /dev/null
sudo echo "vm.vfs_cache_pressure = 50" | sudo tee --append /etc/sysctl.conf > /dev/null
sudo echo "/swapfile   none    swap    sw    0   0" | sudo tee --append /etc/fstab > /dev/null

# Disable firewall (this is not production)
sudo ufw disable

echo Configuring networking....
# To permit IP packets pass through different networks,
# the network card should be configured with routing capability.
sudo echo "net.ipv4.ip_forward = 1" | sudo tee --append /etc/sysctl.conf > /dev/null
sudo echo "net.ipv4.conf.all.rp_filter=0" | sudo tee --append /etc/sysctl.conf > /dev/null
sudo echo "net.ipv4.conf.default.rp_filter=0" | sudo tee --append /etc/sysctl.conf > /dev/null
sudo echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee --append /etc/sysctl.conf > /dev/null
sudo echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee --append /etc/sysctl.conf > /dev/null
sudo echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee --append /etc/sysctl.conf > /dev/null
#sudo echo "net.ipv4.conf.ens32.proxy_arp = 1" | sudo tee --append /etc/sysctl.conf > /dev/null
sudo sysctl -p

# allow OpenStack nodes to route packets out through NATed network on HOST (this is the vagrant managed nic)
sudo iptables -t nat -A POSTROUTING -o ens32 -j MASQUERADE

# Update host configuration
sudo bash -c "echo 'openstack' > /etc/hostname"
#export eth1=`ifconfig eth1 | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`
sudo bash -c 'cat > /etc/hosts' <<EOF
127.0.0.1         localhost
192.168.27.100    openstack.stackinabox.io openstack
EOF

sudo hostname openstack

echo enable cgroup memory limits
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
sudo ifconfig ens34 0.0.0.0
sudo ifconfig ens34 promisc
sudo ip link set dev ens34 up
# sudo ip link set dev ens34 mtu 1450

# Fix permissions on current tty so screens can attach
sudo chmod go+rw tty

# gentelmen start your engines
echo "Installing DevStack"
cd /opt/stack/devstack
./stack.sh
if [ $? -eq 0 ]
then
 echo "Finished installing DevStack"
else
  echo "Error installing DevStack"
  exit $?
fi

# bridge eth2 to ovs for our public network
# sudo ovs-vsctl add-port br-ex ens34
sudo ifconfig br-ex promisc up

# assign ip from public network to bridge (br-ex)
sudo bash -c 'cat >> /etc/network/interfaces' <<'EOF'
auto ens34
iface ens34 inet manual
    address 0.0.0.0
    mtu 1450
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

# sudo ip link set dev ens32 mtu $MTU
# sudo ip link set dev ens33 mtu $MTU

cp /vagrant/scripts/stackinabox/stack-noscreenrc /opt/stack/devstack/stack-noscreenrc
chmod 755 /opt/stack/devstack/stack-noscreenrc
sudo cp /vagrant/scripts/stackinabox/devstack /etc/init.d/devstack
sudo chmod +x /etc/init.d/devstack
sudo update-rc.d devstack start 98 2 3 4 5 . stop 02 0 1 6 .

# Script only works if sudo caches the password for a few minutes
sudo true

# install docker
sudo apt-get update
sudo apt-get install -qqy apt-transport-https ca-certificates
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

sudo touch /etc/apt/sources.list.d/docker.list
sudo bash -c 'echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" > /etc/apt/sources.list.d/docker.list'

sudo apt-get update
sudo apt-get purge lxc-docker

sudo apt-get update
sudo apt-get install -qqy docker-engine

# Install docker-compose
COMPOSE_VERSION=`git ls-remote https://github.com/docker/compose | grep refs/tags | grep -oP "[0-9]+\.[0-9]+\.[0-9]+$" | tail -n 1`
sudo sh -c "curl -L https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose"
sudo chmod +x /usr/local/bin/docker-compose
sudo sh -c "curl -L https://raw.githubusercontent.com/docker/compose/${COMPOSE_VERSION}/contrib/completion/bash/docker-compose > /etc/bash_completion.d/docker-compose"

# Install docker-cleanup command
sudo cp /vagrant/scripts/docker/docker-cleanup.sh /usr/local/bin/docker-cleanup
sudo chmod +x /usr/local/bin/docker-cleanup

# add vagrant user to docker group
sudo usermod -aG docker vagrant
newgrp docker

# have docker listen on a port instead of a unix socket for remote administration
sudo bash -c 'cat > /etc/systemd/system/docker.socket' <<'EOF'
[Socket]
ListenStream=/var/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker
EOF

sudo mkdir -p /etc/systemd/system/docker.service.d

# have docker utilze lxc to launch containers
sudo bash -c 'cat > /etc/systemd/system/docker.service.d/lxc.conf' <<'EOF'
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network.target docker.socket firewalld.service
Requires=docker.socket

[Service]
Type=notify
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// --iptables=false --ip-masq=true --ip-forward=true --max-concurrent-downloads=5 --max-concurrent-uploads=5 --mtu 1500 --insecure-registry 192.168.27.100:5555
ExecReload=/bin/kill -s HUP $MAINPID
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
TimeoutStartSec=0
Delegate=yes
KillMode=process
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target
EOF

# Docker enables IP forwarding by itself, but by default systemd overrides
# the respective sysctl setting. The following disables this override (for all interfaces):
sudo bash -c 'cat > /etc/systemd/network/ipforward.network' <<'EOF'
[Network]
IPForward=ipv4
EOF

sudo bash -c 'cat > /etc/sysctl.d/99-docker.conf' <<'EOF'
net.ipv4.ip_forward = 1
EOF

sudo sysctl -w net.ipv4.ip_forward=1

# adjust the number of processes allowed by systemd
sudo bash -c 'cat > /etc/systemd/system/docker.service.d/tasks.conf' <<'EOF'
[Service]
TasksMax=infinity
EOF

echo "reload/restart docker service"
sudo systemctl daemon-reload
#sudo systemctl restart systemd-networkd
sudo systemctl restart docker.service

# set mysqld apparmor profile to disabled
# this profile effects lxc containers run on this host when using docker
sudo ln -s /etc/apparmor.d/usr.sbin.mysqld /etc/apparmor.d/disable/
sudo apparmor_parser -R /etc/apparmor.d/usr.sbin.mysqld

# install 'shellinabox' to make using this image on windows easier
# shellinabox will be available at http://192.168.27.100:4200
echo "install shellinabox"
sudo apt-get install -y shellinabox
sudo sed -i 's/--no-beep/--no-beep --disable-ssl/g' /etc/default/shellinabox
sudo /etc/init.d/shellinabox restart

# install java (for use with udclient)
# cd /tmp
# wget -Nnv http://artifacts.stackinabox.io/ibm/java-jre/latest.txt
# ARTIFACT_VERSION=$(cat latest.txt)
# ARTIFACT_DOWNLOAD_URL=http://artifacts.stackinabox.io/ibm/java-jre/$ARTIFACT_VERSION/ibm-java-jre-$ARTIFACT_VERSION-linux-x86_64.tgz

# sudo mkdir -p /opt/java
# sudo wget -Nnv $ARTIFACT_DOWNLOAD_URL
# sudo tar -zxf ibm-java-jre-$ARTIFACT_VERSION-linux-x86_64.tgz -C /opt/java/
# sudo touch /etc/profile.d/java_home.sh
# sudo bash -c 'cat >> /etc/profile.d/java_home.sh' <<'EOF'
# export JAVA_HOME=/opt/java/ibm-java-x86_64-71/jre
# export PATH=$JAVA_HOME/bin:$PATH
# EOF
# sudo chmod 755 /etc/profile.d/java_home.sh
# sudo rm -f /tmp/ibm-java-jre-$ARTIFACT_VERSION-linux-x86_64.tgz

cp /vagrant/scripts/stackinabox/admin-openrc.sh /home/vagrant
cp /vagrant/scripts/stackinabox/demo-openrc.sh /home/vagrant
cp /vagrant/scripts/stackinabox/openrc /home/vagrant

# add HOST_IP to ALLOWED_HOSTS of OpenStack Dashboard Apache config
sudo bash -c 'cat >> /opt/stack/horizon/openstack_dashboard/settings.py' <<'EOF'
ALLOWED_HOSTS = ['*']
EOF

exit 0
