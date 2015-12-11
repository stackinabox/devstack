#!/bin/bash

topDir=$(pwd)
pushd $topDir/vagrant
cat >> $(topDir)/vagrant/Personalization <<EOF
# Use NFS? (won't work on windows)
\$use_nfs = false

# Box name
\$box = "stackinabox"

# Box url
\$box_url = "$(topDir)/build/stackinabox.box"

# Number of CPU's (min 2, recommend 4) adjust to your machine
\$cpus = 2

# Amount of RAM (min 4096, recommed 8192) adjust to your machine
\$memory = 4096

# Second Disk (used for lxd backing store)
\$disk = '$HOME/VirtualBox VMs/stackinabox/box-disk2.vmdk'
EOF
vagrant up --provider=virtualbox
sleep 60 #wait for OpenStack services in vm to start completely
popd

