#!/bin/bash

# partition the data disk
disks=$(lsblk | grep disk | awk '{if ($1) print $1}')
for disk in $disks; do
  d="/dev/${disk}"
  partition_count=$(ls $d* | wc -l)
  if [ $partition_count -eq 1 ]; then
    # confirm that no device UUID exists for this disk
    dev_count=$(sudo blkid | grep -c "$d")
    if [ $dev_count -eq 0 ]; then
      echo "partition disk $d"
      sudo parted $d mklabel msdos
      sudo parted -a optimal $d mkpart primary ext4 0% 100%
      dev="${d}1"
      echo "format $dev"
      sudo mkfs.ext4 -L DATA $dev
    fi
  fi
done

disks=$(ls /dev/*db)
for d in $disks; do
  partition_count=$(ls $d* | wc -l)
  if [ $partition_count -eq 2 ]; then
    dev="${d}1"
    dev_uuid=$(sudo blkid $dev | sed -e 's/.*\ UUID="//g' -e 's/".*//g')
    fstab_count=$(grep -c "$dev_uuid" /etc/fstab)
    if [ $fstab_count -eq 0 ]; then
      echo "mount $dev to /data"
      sudo mkdir -p /data
      echo "UUID=$dev_uuid   /data   ext4   defaults   0   0" | cat /etc/fstab - > /tmp/fstab.tmp
      sudo mv /tmp/fstab.tmp /etc/fstab
      sudo mount /data
      sudo chmod 777 /data
    fi
  fi
done


