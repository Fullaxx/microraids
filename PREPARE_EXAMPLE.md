First we need to make sure we have all the appropriate tools. \ 
For Ubuntu users, the following command will ensure you have all the right repositories \
and tools.  For users of other distributions, consult your specific distro documentation \
to install the `apcalc sgdisk hdparm dd losetup mdadm` packages. \

```
sudo apt-add-repository universe; sudo apt update; sudo apt install apcalc-common mdadm
```


In this example we will start with 8 blank disks that we assume start at /dev/sdd and go through /dev/sdk: /dev/sd[defghijk] \
Modify these locations to match your environment. In our example, we have existing disks at /dev/sd[abc] that we don't want to touch \
If you need to wipe a disk, you can use the command: sgdisk -Z <disk> \
To prepare our disks, we will create a single partition on each disk. \
The second command will ensure that the new partition has type code 8300.
```
for DISK in /dev/sd[defghijk]; do sgdisk -n 1:0:0 ${DISK}; done
for DISK in /dev/sd[defghijk]; do sgdisk -t 1:8300 ${DISK}; done
```

Next we will put a btrfs filesystem on each new partition. \
I chose btrfs for the data checksumming feature. \
Scrubbing the disk regularly will allow us to prematurely identify issues that can be resolved. \
We will assign a label to each filesystem that matches the serial number of the drive.
```
for DISK in /dev/sd[defghijk]; do
  PART="${DISK}1"
  LABEL=$(hdparm -I ${DISK} | grep 'Serial Number:' | awk '{print $3}')
  mkfs.btrfs -L ${LABEL} ${PART}
done
```

Assigning the FS labels that match serial numbers will allow us to easily group our disks by function.
```
ls -l /dev/disk/by-label/VA??????
lrwxrwxrwx 1 root root 10 Apr 14 12:05 /dev/disk/by-label/VAHAW81L -> ../../sdg1
lrwxrwxrwx 1 root root 10 Apr 14 12:05 /dev/disk/by-label/VAHBY2ML -> ../../sdi1
lrwxrwxrwx 1 root root 10 Apr 14 12:05 /dev/disk/by-label/VAHC5NWL -> ../../sdj1
lrwxrwxrwx 1 root root 10 Apr 14 12:05 /dev/disk/by-label/VAJDV17L -> ../../sdh1
lrwxrwxrwx 1 root root 10 Apr 14 12:05 /dev/disk/by-label/VAJELEPL -> ../../sdd1
lrwxrwxrwx 1 root root 10 Apr 14 12:05 /dev/disk/by-label/VAJFPNDL -> ../../sdf1
lrwxrwxrwx 1 root root 10 Apr 14 12:05 /dev/disk/by-label/VAJGDMHL -> ../../sde1
lrwxrwxrwx 1 root root 10 Apr 14 12:05 /dev/disk/by-label/VAJHDMHL -> ../../sdk1
```

Last we mount our new filesystems and create a map file. \
This map file will be used by the other scripts. \
Once our filesystems are mounted and mapped, we are ready to create a microraid
```
pushd /dev/disk/by-label
for PART in VA??????; do
  mkdir /mnt/${PART}
  mount ${PART} /mnt/${PART}
  echo "/mnt/${PART}" >> ~/mnt_locations.map
done
popd
```
