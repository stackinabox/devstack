stackinabox
===========

#### OpenStack (Liberty) w/ Nuetron networking in Vagrant using Ubuntu's nova-compute-lxd

This Vagrant project will give you a running instance of OpenStack Liberty from the "stable/liberty" branch running in a Ubuntu Trusty 64 image downloaded directly from Ubuntu's cloud image server:

    config.vm.box = "ubuntu/trusty64"  
    config.vm.box_url = "https://atlas.hashicorp.com/ubuntu/boxes/trusty64"

This project provides a great resource for testing software that relies on an existing OpenStack server with Neutron networking. This is a completely self-contained OpenStack configuration once you have run the initial `vagrant up` and devstack has been downloaded and installed. Once running you can simply use `vagrant halt` to stop the OpenStack server and `vagrant up` to start it back up.  If you want to reset the OpenStack server then you'll need to run `vagrant destroy` and `vagrant up` again (network connection will be required each time you run `vagrant up` for the first time).

## Quick Start:
  #  Download & install GIT for your platform  
  #  Clone this repo to your system
    ````git clone https://github.com/tpouyer/stackinabox.git````  
  #  Change into the newly cloned 'stackinabox' directory
  #  Now change into the 'vagrant' directory
  #  Copy the `Personalization.dict` in the same directory with the name `Personalization`
  #  Note if you have a problem with nfs shares (or you are running on windows) open the newly
     copied `Personalization` file and change the `$use_nfs = true` property to `$use_nfs = false`
  #  Change to the `stackinabox/scripts/install-vagrant` folder and run the following command for your system:  
     `./install-vagrant-linux-ubuntu.sh`  
  #  Change back into the `stackinabox/vagrant` folder and exectue the build:
     `build.sh`  
  #  Wait for the process to complete (will take 30 - 90 mins depending on your connection speed)
  #  Generate a base box package that can be used by other vagrant projects:
     `package.sh`  

#### Vagrant Base Box

If you are only looking for a vagrant base box with openstack already installed that you can use for your own vagrant projects then you can check out the releases of the __stackina-base-box__ project.

### Credits
This project was adapted from the project [devstack-vm](https://github.com/lorin/devstack-vm) and incorporates many tips and suggestions found around the web on devstack and vagrant forums, too many to list or otherwise locate at this point.