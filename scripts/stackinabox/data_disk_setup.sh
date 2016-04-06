#!/bin/bash

# install btrfs helpers
sudo apt-get install -y btrfs-tools

# partition the data disk
disks=$(ls /dev/sd?)
for d in $disks; do
  partition_count=$(ls $d* | wc -l)
  if [ $partition_count -eq 1 ]; then
    # confirm that no device UUID exists for this disk
    dev_count=$(sudo blkid | grep -c "$d")
    if [ $dev_count -eq 0 ]; then
      echo "partition disk $d"
      sudo parted $d mklabel msdos
      sudo parted -a optimal $d mkpart primary btrfs 0% 100%
      dev="${d}1"
      echo "format $dev"
      sudo mkfs.btrfs -L DATA $dev
    fi
  fi
done

disks=$(ls /dev/sdb)
for d in $disks; do
  partition_count=$(ls $d* | wc -l)
  if [ $partition_count -eq 2 ]; then
    dev="${d}1"
    dev_uuid=$(sudo blkid $dev | sed -e 's/.*UUID="//g' -e 's/".*//g')
    fstab_count=$(grep -c "$dev_uuid" /etc/fstab)
    if [ $fstab_count -eq 0 ]; then
      echo "mount $dev to /var/lib/lxd"
      sudo mkdir -p /var/lib/lxd
      echo "UUID=$dev_uuid   /var/lib/lxd   btrfs   defaults,user_subvol_rm_allowed   0   0" | cat /etc/fstab - > /tmp/fstab.tmp
      sudo mv /tmp/fstab.tmp /etc/fstab
      sudo mount /var/lib/lxd
    fi
  fi
done
