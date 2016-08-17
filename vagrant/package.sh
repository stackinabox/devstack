#!/bin/bash

topDir=$(pwd)
pushd $topDir/vagrant

vagrant halt ## make sure vagrant vm is no longer running

# create/clean build dir
mkdir -p $topDir/builds
rm -f $topDir/builds/*

# defragment disks
#$topDir/scripts/minimize/vmware-vdiskmanager -d $HOME/VirtualBox\ VMs/stackinabox/box-disk1.vmdk
#$topDir/scripts/minimize/vmware-vdiskmanager -d $HOME/VirtualBox\ VMs/stackinabox/box-disk2.vmdk

# shrink disks
#$topDir/scripts/minimize/vmware-vdiskmanager -k $HOME/VirtualBox\ VMs/stackinabox/box-disk1.vmdk
#$topDir/scripts/minimize/vmware-vdiskmanager -k $HOME/VirtualBox\ VMs/stackinabox/box-disk2.vmdk

# create vagrant box
vagrant package --base stackinabox --output $topDir/build/stackinabox.box

# copy
cp $topDir/demo_key.priv $topDir/build/

popd
