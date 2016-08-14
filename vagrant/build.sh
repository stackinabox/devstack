#!/bin/bash

topDir=$(pwd)
pushd $topDir/vagrant

touch $topDir/vagrant/Personalization
cat > $topDir/vagrant/Personalization <<EOF
# Use NFS? (won't work on windows)
\$use_nfs = false

# Box name
\$box = "bento/ubuntu-16.04"

# Box url
\$box_url = "https://atlas.hashicorp.com/bento/boxes/ubuntu-16.04"

# Number of CPU's (min 2, recommend 4) adjust to your machine
\$cpus = 8

# Amount of RAM (min 4096, recommed 8192) adjust to your machine
\$memory = 16384

# Which release branch should we build? ( stable/juno | stable/kilo | stable/liberty | master )
\$release_branch = "stable/mitaka"

# Second Disk (used for lxd backing store)
\$disk = '$HOME/VirtualBox VMs/stackinabox/box-disk2.vmdk'
EOF
cat $topDir/vagrant/Personalization
echo "Bringing up Vm for Devstack provisioning"
vagrant up --provision-with "openstack" --provider=virtualbox
echo "Rebooting..."
vagrant reload
echo "wait for OpenStack services in vm to start completely.."
sleep 60 
echo "Bringing up Vm for post-provisioning config"
vagrant provision --provision-with "post-config"
popd
