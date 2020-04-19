## Requirements
First we need to make sure we have all the appropriate tools. \
Please consult this chart for help with installing the required packages. \
If your OS is not listed, please help us fill out the table, or submit a request via github.

| Operating System   | Commands (as root)                                                               |
| ------------------ | -------------------------------------------------------------------------------- |
| CentOS             | `yum install -y epel-release; yum install -y calc gdisk hdparm mdadm`            |
| Debian             | `apt update; apt install --no-install-recommends -y apcalc gdisk hdparm mdadm`   |
| Fedora             | `yum install -y calc gdisk hdparm mdadm`                                         |
| Ubuntu             | `apt-add-repository universe; apt update; apt install apcalc gdisk hdparm mdadm` |

## Disk Partitioning
In this example we will start with 8 blank disks. \
Lets assume that we want to ignore disks sda, sdb, and sdc. \
We will modify disks /dev/sdd through /dev/sdk using /dev/sd[defghijk] \
Modify these locations to match your environment. \
If you need to wipe a disk, you can use the command: `sgdisk -Z <disk>` \
To prepare our disks, we will create a single partition on each disk. \
The second command will ensure that the new partition has type code 8300.
```bash
for DISK in /dev/sd[defghijk]; do sgdisk -n 1:0:0 ${DISK}; done
for DISK in /dev/sd[defghijk]; do sgdisk -t 1:8300 ${DISK}; done
```

## Filesystem Creation
Next we will put a btrfs filesystem on each new partition. \
I chose btrfs because it supports checksumming of data blocks via the scrub command. \
[Scrubbing](https://github.com/Fullaxx/microraids/blob/master/CHECK_EXAMPLE.md) the disk regularly will allow us to prematurely identify issues that can be resolved. \
NOTE: We will *NOT* be using the (btrfs-raid)[https://btrfs.wiki.kernel.org/index.php/RAID56] feature, but just a generic btrfs filesystem on individual partitions. \
We will assign a label to each filesystem that matches the serial number of the drive. \
The last line of the for loop will create the map file. This will be used by other scripts.
```bash
for DISK in /dev/sd[defghijk]; do
  PART="${DISK}1"
  LABEL=$(hdparm -I ${DISK} | grep 'Serial Number:' | awk '{print $3}')
  mkfs.btrfs -f -L ${LABEL} ${PART}
  mkdir -p /mnt/${LABEL}
  echo "/mnt/${LABEL}" >> ~/mnt_locations.map
done
```

## Disks, Partitions, and Labels
Assigning the FS labels that match serial numbers will allow us to easily group our disks by function. \
Use `ls -l /dev/disk/by-label` to see how the labels are mapped to your disks.

```bash
ls -l /dev/disk/by-label/
lrwxrwxrwx 1 root root 10 Apr 14 12:05 /dev/disk/by-label/VAHAW81L -> ../../sdg1
lrwxrwxrwx 1 root root 10 Apr 14 12:05 /dev/disk/by-label/VAHBY2ML -> ../../sdi1
lrwxrwxrwx 1 root root 10 Apr 14 12:05 /dev/disk/by-label/VAHC5NWL -> ../../sdj1
lrwxrwxrwx 1 root root 10 Apr 14 12:05 /dev/disk/by-label/VAJDV17L -> ../../sdh1
lrwxrwxrwx 1 root root 10 Apr 14 12:05 /dev/disk/by-label/VAJELEPL -> ../../sdd1
lrwxrwxrwx 1 root root 10 Apr 14 12:05 /dev/disk/by-label/VAJFPNDL -> ../../sdf1
lrwxrwxrwx 1 root root 10 Apr 14 12:05 /dev/disk/by-label/VAJGDMHL -> ../../sde1
lrwxrwxrwx 1 root root 10 Apr 14 12:05 /dev/disk/by-label/VAJHDMHL -> ../../sdk1
```

Using the `mount` command, we can see where all our newly created partitions got mounted.
```bash
mount                 

/dev/sdg1 on /mnt/VAHAW81L type btrfs (rw)
/dev/sdi1 on /mnt/VAHBY2ML type btrfs (rw)
/dev/sdj1 on /mnt/VAHC5NWL type btrfs (rw)
/dev/sdh1 on /mnt/VAJDV17L type btrfs (rw)
/dev/sdd1 on /mnt/VAJELEPL type btrfs (rw)
/dev/sdf1 on /mnt/VAJFPNDL type btrfs (rw)
/dev/sde1 on /mnt/VAJGDMHL type btrfs (rw)
/dev/sdk1 on /mnt/VAJHDMHL type btrfs (rw)
```
