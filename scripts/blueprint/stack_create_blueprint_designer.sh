#!/bin/bash

source /home/vagrant/demo-openrc.sh labstack
heat stack-create -f /vagrant/scripts/blueprint/designer.yml -e /vagrant/scripts/blueprint/local.env blueprint-designer