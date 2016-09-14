#!/bin/bash -ux

# delete all linux headers
#dpkg --list | awk '{ print $2 }' | grep linux-headers-4*- | grep -v `uname -r` | xargs apt-get -y purge
sudo dpkg --list | awk '{ print $2 }' | grep linux-headers-4-* | grep -v 4.4.0-36 | sudo xargs apt-get purge

# this removes specific linux kernels, such as
# linux-image-3.11.0-15-generic but 
# * keeps the current kernel
# * does not touch the virtual packages, e.g.'linux-image-generic', etc.
#
dpkg --list | awk '{ print $2 }' | grep 'linux-image-4.*-generic' | grep -v `uname -r` | sudo xargs apt-get -y purge

# delete linux source
dpkg --list | awk '{ print $2 }' | grep linux-source | sudo xargs apt-get -y purge

# delete development packages
sudo dpkg --list | awk '{ print $2 }' | grep -- '-dev$' | sudo xargs apt-get -qqy purge

# delete compilers and other development tools (can't do this otherwise dkms* dynamic kernel modules will be removed')
#sudo apt-get -y purge cpp gcc g++

# delete X11 libraries
sudo apt-get -qqy purge libx11-data x11-common

# delete obsolete networking
sudo apt-get -qqy purge ppp pppconfig pppoeconf

# clean up other stuff
sudo apt-get -qqy man xkb-data libx11-data eject locales radvd 

# delete oddities
sudo apt-get -qqy purge popularity-contest

# delete cloud-init
sudo apt-get -qqy purge cloud-init

# delete ubuntu's landscape-client
sudo apt-get -qqy purge landscape-client

# delete radvd package
sudo apt-get -qqy purge radvd

# delete puppet
sudo apt-get -qqy purge puppet

# delete chef
sudo apt-get -qqy purge chef

# delete .git directories from /opt/stack/xxx
find /opt/stack -maxdepth 2 -type d | grep '.git' | xargs rm -rf

# delete 'doc' directories from /opt/stack/xxx
find /opt/stack -maxdepth 2 -type d | grep 'doc' | xargs rm -rf

# remove all uneeded packages acording to apt
sudo apt-get -qqy autoremove
sudo apt-get -qqy autoclean
sudo apt-get -qqy clean

sudo rm -rf /var/lib/apt/lists/*

# delete python library cache
sudo rm -rf /var/cache/pip/*

# Clean up the last logged in users logs
sudo rm -f /var/log/wtmp /var/log/btmp

# clean up log files /var/log
sudo bash -c "find /var/log -type f | grep '.log' | xargs truncate -s 0"
find /opt/stack/logs -type f | grep '.log' | xargs truncate -s 0

# clear terminal history
history -c

# Whiteout the swap partition to reduce box size 
# Swap is disabled till reboot 
#readonly swapuuid=$(/sbin/blkid -o value -l -s UUID -t TYPE=swap)
#readonly swappart=$(readlink -f /dev/disk/by-uuid/"$swapuuid")
#swapoff /swapfile
#dd if=/dev/zero of=/swapfile bs=1M || echo "dd exit code $? is suppressed" 
#mkswap /swapfile

# Zero disk
sudo dd if=/dev/zero of=/EMPTY bs=1M

sudo rm -rf /EMPTY
