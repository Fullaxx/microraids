## Requirements
First we need to make sure we have all the appropriate tools. \
Please consult this chart for help with installing the required packages. \
If your OS is not listed, please help us fill out the table, or submit a request via github.

| Operating System   | Commands (as root)                                                               |
| ------------------ | -------------------------------------------------------------------------------- |
| CentOS             | `yum install -y epel-release; yum install -y calc gdisk hdparm mdadm`            |
| Debian             | `apt update; apt install --no-install-recommends -y apcalc gdisk hdparm mdadm`   |
| Fedora             | `yum install -y calc gdisk hdparm mdadm`                                         |
| Ubuntu             | `apt update; apt install apcalc btrfs-progs gdisk hdparm mdadm`                  |

## Disk Partitioning
In this example we will start with 8 blank disks. \
Lets assume that we want to ignore disks sda and sdb. \
We will modify disks /dev/sdc through /dev/sdj using /dev/sd[cdefghij] \
Modify these locations to match your environment. \
If you need to wipe a disk, you can use the command: `sgdisk -Z <disk>` \
To prepare our disks, we will create a single partition on each disk. \
The second command will ensure that the new partition has type code 8300.
```bash
for DISK in /dev/sd[cdefghij]; do sgdisk -n 1:0:0 ${DISK}; done
for DISK in /dev/sd[cdefghij]; do sgdisk -t 1:8300 ${DISK}; done
```

## Filesystem Creation
Next we will put a btrfs filesystem on each new partition. \
I chose btrfs because it supports checksumming of data blocks via the scrub command. \
[Scrubbing](https://github.com/Fullaxx/microraids/blob/master/CHECK_EXAMPLE.md) the disk regularly will allow us to prematurely identify issues that can be resolved. \
NOTE: We will *NOT* be using the [btrfs-raid](https://btrfs.wiki.kernel.org/index.php/RAID56) feature, but just a generic btrfs filesystem on individual partitions. \
We will assign a label to each filesystem that matches the serial number of the drive. \
The last line of the for loop will create the map file. This will be used by other scripts.
```bash
for DISK in /dev/sd[cdefghij]; do
  PART="${DISK}1"
  LABEL=$(hdparm -I ${DISK} | grep 'Serial Number:' | awk '{print $3}')
  mkfs.btrfs -f -L ${LABEL} ${PART}
  mkdir -p /mnt/${LABEL}
  mount ${PART} /mnt/${LABEL} -t btrfs
  echo "/mnt/${LABEL}" >> mnt_locations.map
done
```

## Disks, Partitions, and Labels
Assigning the FS labels that match serial numbers will allow us to easily group our disks by function. \
Also, there is no guarantee that these disks will be given the same drive letter every time at startup. \
Mounting drives by serial ensures we get the expected results upon every startup. \
Use `ls -l /dev/disk/by-label` to see how the labels are mapped to your disks.

```bash
ls -l /dev/disk/by-label/
lrwxrwxrwx 1 root root 10 Apr 19 13:46 VAHJW81L -> ../../sdg1
lrwxrwxrwx 1 root root 10 Apr 19 13:46 VAHKY2ML -> ../../sdi1
lrwxrwxrwx 1 root root 10 Apr 19 13:46 VAHX5NWL -> ../../sdj1
lrwxrwxrwx 1 root root 10 Apr 19 13:46 VAJ0V17L -> ../../sdh1
lrwxrwxrwx 1 root root 10 Apr 19 13:46 VAJ7LEPL -> ../../sdc1
lrwxrwxrwx 1 root root 10 Apr 19 13:46 VAJBPNDL -> ../../sde1
lrwxrwxrwx 1 root root 10 Apr 19 13:46 VAJDDMHL -> ../../sdd1
lrwxrwxrwx 1 root root 10 Apr 19 13:46 VDG04BHK -> ../../sdf1
```

Using the `mount` command, we can see where all our newly created partitions got mounted.
```bash
mount                 

/dev/sdg1 on /mnt/VAHJW81L type btrfs (rw,nosuid,nodev,noatime,nodiratime)
/dev/sdi1 on /mnt/VAHKY2ML type btrfs (rw,nosuid,nodev,noatime,nodiratime)
/dev/sdj1 on /mnt/VAHX5NWL type btrfs (rw,nosuid,nodev,noatime,nodiratime)
/dev/sdh1 on /mnt/VAJ0V17L type btrfs (rw,nosuid,nodev,noatime,nodiratime)
/dev/sdc1 on /mnt/VAJ7LEPL type btrfs (rw,nosuid,nodev,noatime,nodiratime)
/dev/sde1 on /mnt/VAJBPNDL type btrfs (rw,nosuid,nodev,noatime,nodiratime)
/dev/sdd1 on /mnt/VAJDDMHL type btrfs (rw,nosuid,nodev,noatime,nodiratime)
/dev/sdf1 on /mnt/VDG04BHK type btrfs (rw,nosuid,nodev,noatime,nodiratime)
```

I use a script like this to ensure that my disks get mounted in the same place every startup. \
```bash
for PART in /dev/disk/by-label/PV[ABCD]??????; do
  SERIAL=`basename ${PART}`
  mkdir -p /mnt/${SERIAL}
  mount ${PART} /mnt/${SERIAL} -t btrfs -o rw,nosuid,nodev,noatime,nodiratime
done
```
