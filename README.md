stackinabox [![Build Status](https://travis-ci.org/tpouyer/stackinabox.svg?branch=master)](https://travis-ci.org/tpouyer/stackinabox)
============

#### OpenStack Liberty (DevStack) w/ Neutron networking in Vagrant using Ubuntu's [LXD](https://github.com/lxc/nova-lxd)

## Quick Start:
  - Download & install [GIT](https://git-scm.com/) for your platform
  - Clone this repo to your system
    ````git clone https://github.com/tpouyer/stackinabox.git````  
  - cd into the newly cloned 'stackinabox' directory
  - Install pre-reqs:
    - [VirtualBox 5.0.10](https://www.virtualbox.org/wiki/Downloads) Don't need the Extension Pack
    - [Vagrant](https://www.vagrantup.com/downloads.html) v1.7+
    - Install vagrant plugins:
      - [vbguest](https://github.com/dotless-de/vagrant-vbguest) Run ````vagrant plugin install vagrant-vbguest````
      - [cachier](https://github.com/fgrehm/vagrant-cachier) Run ````vagrant plugin install vagrant-cachier````
  - Copy `vagrant/Personalization.dist` to `vagrant/Personalization` and edit parameters for your needs
    ````cp vagrant/Personalization.dist vagrant/Personalization````
    - __NOTE__
  - run build:
    ````vagrant/build.sh````
  - You can now open your browser to `http://192.168.27.100` to see the Horizon web console
    - You can login as demo user with:
      - username: `demo`
      - password: `labstack`
    - You can login as admin user with:
      - username: `admin`
      - password: `labstack`
  - You ssh into the vagrant machine using:
    ````ssh vagrant@192.168.27.100````
    - password: `vagrant`
    - or you can use vagrant's passwordless ssh support:
    ````cd vagrant;vagrant ssh````
  - You can authenticate with Keystone to run the OpenStack commandline tools by ssh'ing into the vagrant machine and running:
    ````source /opt/stack/devstack/openrc demo demo````
    - or
    ````source /opt/stack/devstack/openrc admin admin````


#### Vagrant Base Box

If you are only looking for a vagrant base box with openstack already installed that you can use for your own vagrant projects then you can check out the releases of the [stackina-base-box](https://github.com/tpouyer/stackina-base-box) project.

### Credits
This project was adapted from the project [devstack-vm](https://github.com/lorin/devstack-vm) and incorporates many tips and suggestions found around the web on devstack and vagrant forums, too many to list or otherwise locate at this point.