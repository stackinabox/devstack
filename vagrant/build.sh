#!/bin/bash

echo "Bringing up Vm for Devstack provisioning"
vagrant up --provision-with "openstack"

echo "Rebooting..."
vagrant reload

echo "wait for OpenStack services in vm to start completely.."
sleep 60 

echo "Bringing up Vm for post-provisioning config"
vagrant provision --provision-with "post-config"
sleep 60

echo "Adding Docker HEAT Plugins to heat engine"
vagrant provision --provision-with "docker-heat"

echo "Rebooting..."
vagrant reload

