#!/bin/bash

topDir=$(pwd)
pushd $topDir/vagrant
cp $topDir/vagrant/Personalization.dist $topDir/vagrant/Personalization
cat >> $topDir/vagrant/Personalization <<EOF

# Second Disk (used for lxd backing store)
\$disk = '$HOME/VirtualBox VMs/stackinabox/box-disk2.vmdk'
EOF
vagrant up --provider=virtualbox
sleep 60 #wait for OpenStack services in vm to start completely
popd

