#!/bin/bash 

# exit on error
#set -e

DATE=`date +%Y%m%d -d "yesterday"`
echo "downloading trusty-server-cloudimg-amd64-root.tar.xz image archive for import"
wget -Nnv --progress=bar:force:noscroll https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-root.tar.xz -O ubuntu-1404-amd64-root.tar.xz
glance image-create --name 'ubuntu-1404-amd64' \
	--container-format bare \
	--disk-format raw \
	--visibility public \
	--min-disk 1 \
	--property architecture=x86_64 \
	--property hypervisor_type=lxc \
	--property os_distro=ubuntu \
	--property os_version=14.04 \
	--property vm_mode=exe < ubuntu-1404-amd64-root.tar.xz

wget -Nnv --progress=bar:force:noscroll https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-root.tar.xz -O ubuntu-1604-amd64-root.tar.xz
glance image-create --name 'ubuntu-1604-amd64' \
	--container-format bare \
	--disk-format raw \
	--visibility public \
	--min-disk 1 \
	--property architecture=x86_64 \
	--property hypervisor_type=lxc \
	--property os_distro=ubuntu \
	--property os_version=16.04 \
	--property vm_mode=exe < ubuntu-1604-amd64-root.tar.xz

# wget -Nv https://uk.images.linuxcontainers.org/images/opensuse/13.2/amd64/default/${DATE}_00:53/rootfs.tar.xz -O opensuse-132-amd64-root.tar.xz
# glance image-create --name 'opensuse-132-amd64' \
# 	--container-format bare \
# 	--disk-format raw \
# 	--visibility public \
# 	--min-disk 1 \
# 	--property architecture=x86_64 \
# 	--property hypervisor_type=lxc \
# 	--property os_distro=opensuse \
# 	--property os_version=13.2 \
# 	--property vm_mode=exe < opensuse-132-amd64-root.tar.xz


# wget -Nv https://uk.images.linuxcontainers.org/images/alpine/3.1/amd64/default/${DATE}_17:50/rootfs.tar.xz -O alpine-31-amd64-root.tar.xz
# glance image-create --name 'alpine-31-amd64' \
# 	--container-format bare \
# 	--disk-format raw \
# 	--visibility public \
# 	--min-disk 1 \
# 	--property architecture=x86_64 \
# 	--property hypervisor_type=lxc \
# 	--property os_distro=alpine \
# 	--property os_version=3.1 \
# 	--property vm_mode=exe < alpine-31-amd64-root.tar.xz
# wget -Nv https://uk.images.linuxcontainers.org/images/alpine/3.2/amd64/default/${DATE}_17:50/rootfs.tar.xz -O alpine-32-amd64-root.tar.xz
# glance image-create --name 'alpine-32-amd64' \
# 	--container-format bare \
# 	--disk-format raw \
# 	--visibility public \
# 	--min-disk 1 \
# 	--property architecture=x86_64 \
# 	--property hypervisor_type=lxc \
# 	--property os_distro=alpine \
# 	--property os_version=3.2 \
# 	--property vm_mode=exe < alpine-32-amd64-root.tar.xz
# wget -Nv https://uk.images.linuxcontainers.org/images/alpine/3.3/amd64/default/${DATE}_17:50/rootfs.tar.xz -O alpine-33-amd64-root.tar.xz
# glance image-create --name 'alpine-33-amd64' \
# 	--container-format bare \
# 	--disk-format raw \
# 	--visibility public \
# 	--min-disk 1 \
# 	--property architecture=x86_64 \
# 	--property hypervisor_type=lxc \
# 	--property os_distro=alpine \
# 	--property os_version=3.3 \
# 	--property vm_mode=exe < alpine-33-amd64-root.tar.xz
# wget -Nv https://uk.images.linuxcontainers.org/images/alpine/3.4/amd64/default/${DATE}_17:50/rootfs.tar.xz -O alpine-34-amd64-root.tar.xz
# glance image-create --name 'alpine-34-amd64' \
# 	--container-format bare \
# 	--disk-format raw \
# 	--visibility public \
# 	--min-disk 1 \
# 	--property architecture=x86_64 \
# 	--property hypervisor_type=lxc \
# 	--property os_distro=alpine \
# 	--property os_version=3.4 \
# 	--property vm_mode=exe < alpine-34-amd64-root.tar.xz


# wget -Nv https://uk.images.linuxcontainers.org/images/centos/6/amd64/default/${DATE}_02:16/rootfs.tar.xz -O centos-6-amd64-root.tar.xz
# glance image-create --name 'centos-6-amd64' \
# 	--container-format bare \
# 	--disk-format raw \
# 	--visibility public \
# 	--min-disk 1 \
# 	--property architecture=x86_64 \
# 	--property hypervisor_type=lxc \
# 	--property os_distro=centos \
# 	--property os_version=6 \
# 	--property vm_mode=exe < centos-6-amd64-root.tar.xz

# wget -Nv https://uk.images.linuxcontainers.org/images/centos/7/amd64/default/${DATE}_02:16/rootfs.tar.xz -O centos-7-amd64-root.tar.xz
# glance image-create --name 'centos-7-amd64' \
# 	--container-format bare \
# 	--disk-format raw \
# 	--visibility public \
# 	--min-disk 1 \
# 	--property architecture=x86_64 \
# 	--property hypervisor_type=lxc \
# 	--property os_distro=centos \
# 	--property os_version=7 \
# 	--property vm_mode=exe < centos-7-amd64-root.tar.xz

# wget -Nv https://uk.images.linuxcontainers.org/images/oracle/7/amd64/default/${DATE}_11:40/rootfs.tar.xz -O oracle-7-amd64-root.tar.xz
# glance image-create --name 'oracle-7-amd64' \
# 	--container-format bare \
# 	--disk-format raw \
# 	--visibility public \
# 	--min-disk 1 \
# 	--property architecture=x86_64 \
# 	--property hypervisor_type=lxc \
# 	--property os_distro=oracle \
# 	--property os_version=7 \
# 	--property vm_mode=exe < oracle-7-amd64-root.tar.xz

# wget -Nv https://uk.images.linuxcontainers.org/images/fedora/24/amd64/default/${DATE}_01:27/rootfs.tar.xz -O fedora-24-amd64-root.tar.xz
# glance image-create --name 'fedora-24-amd64' \
# 	--container-format bare \
# 	--disk-format raw \
# 	--visibility public \
# 	--min-disk 1 \
# 	--property architecture=x86_64 \
# 	--property hypervisor_type=lxc \
# 	--property os_distro=fedora \
# 	--property os_version=24 \
# 	--property vm_mode=exe < fedora-24-amd64-root.tar.xz

