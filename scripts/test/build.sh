#!/bin/bash

topDir=$(pwd)
pushd $topDir/scripts/test

mkdir -p $topDir/test
git clone https://github.com/tpouyer/stackina-base-box.git $topDir/test

touch $topDir/test/vagrant/Personalization
cat >> $topDir/test/vagrant/Personalization <<EOF
# Use NFS? (won't work on windows)
\$use_nfs = false

# Box name
\$box = "stackina-base-box"

# Box url
\$box_url = "$topDir/build/stackinabox.box"

# Number of CPU's (min 2, recommend 4) adjust to your machine
\$cpus = 4

# Amount of RAM (min 4096, recommed 8192) adjust to your machine
\$memory = 8192
EOF

vagrant up --provider=virtualbox
sleep 60 #wait for OpenStack services in vm to start completely
popd

