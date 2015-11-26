#!/bin/bash -ux

# delete all linux headers
dpkg --list | awk '{ print $2 }' | grep linux-headers | xargs apt-get -y purge

# this removes specific linux kernels, such as
# linux-image-3.11.0-15-generic but 
# * keeps the current kernel
# * does not touch the virtual packages, e.g.'linux-image-generic', etc.
#
dpkg --list | awk '{ print $2 }' | grep 'linux-image-3.*-generic' | grep -v `uname -r` | xargs apt-get -y purge

# delete linux source
dpkg --list | awk '{ print $2 }' | grep linux-source | xargs apt-get -y purge

# delete development packages
dpkg --list | awk '{ print $2 }' | grep -- '-dev$' | xargs apt-get -y purge

# delete compilers and other development tools
apt-get -y purge cpp gcc g++

# delete X11 libraries
apt-get -y purge libx11-data libxmuu1 libx11-6 libxext6

# delete obsolete networking
apt-get -y purge ppp pppconfig pppoeconf

# delete oddities
apt-get -y purge popularity-contest

# delete cloud-init
apt-get -y purge cloud-init

# delete ubuntu's landscape-client
apt-get -y purge landscape-client

# delete radvd package
apt-get -y purge radvd

# delete puppet
apt-get -y purge puppet

# delete chef
apt-get -y purge chef

# delete .git directories from /opt/stack/xxx
find /opt/stack -maxdepth 2 -type d | grep '.git' | xargs rm -rf

# delete 'doc' directories from /opt/stack/xxx
find /opt/stack -maxdepth 2 -type d | grep 'doc' | xargs rm -rf

# remove all uneeded packages acording to apt
apt-get -y autoremove
apt-get -y autoclean
apt-get -y clean

# delete python library cache
rm -rf /var/cache/pip/*

# Clean up the last logged in users logs
rm -f /var/log/wtmp /var/log/btmp

# clean up log files /var/log
find /var/log -type f | grep '.log' | xargs truncate -s 0
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
dd if=/dev/zero of=/EMPTY bs=1M
rm -rf /EMPTY
