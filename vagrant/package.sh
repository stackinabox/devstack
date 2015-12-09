#!/bin/bash -ux

# create/clean build dir
mkdir -p ../build
rm -f ../../build/*

# defragment disks
../scripts/minimize/vmware-vdiskmanager -d ~/VirtualBox\ VMs/stackinabox/box-disk1.vmdk
../scripts/minimize/vmware-vdiskmanager -d ~/VirtualBox\ VMs/stackinabox/box-disk2.vmdk

# shrink disks
../scripts/minimize/vmware-vdiskmanager -k ~/VirtualBox\ VMs/stackinabox/box-disk1.vmdk
../scripts/minimize/vmware-vdiskmanager -k ~/VirtualBox\ VMs/stackinabox/box-disk1.vmdk

# create vagrant box
vagrant package --base stackinabox --output ../../build/stackinabox.box

# copy
cp ../demo_key.priv ../build/

