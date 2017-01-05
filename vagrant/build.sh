#!/bin/bash

# exit on error
set -e

echo "Bringing up Vm for Devstack provisioning"
vagrant up --provision-with "openstack"

echo "Rebooting..."
vagrant reload

echo "wait for OpenStack services in vm to start completely.."
sleep 60 

echo "Bringing up Vm for post-provisioning config"
vagrant provision --provision-with "post-config"
sleep 60

echo "Rebooting..."
vagrant reload

