## Locations Map
After preperation, you should have a locations map. \
This text file is a list of mount points that describe where to place/find each disk image. \
I have 8 disks, so I have 8 mounted partitions. Each image will be on a seperate physical disk.
```bash
cat mnt_locations.map
/mnt/VAJ7LEPL
/mnt/VAJDDMHL
/mnt/VAJBPNDL
/mnt/VDG04BHK
/mnt/VAHJW81L
/mnt/VAJ0V17L
/mnt/VAHKY2ML
/mnt/VAHX5NWL
```

## Choose a Raid Level
This table is a brief overview of the supported raid levels. \
Column 2 shows you the minimum number of images required to start the microraid. \
Column 3 shows the fault tolerance of each raid level. \
Raid-0 has no redundancy, therefore if you lose any image, you will lose data. \
Raid-1 has N copies of data, so you can lose all but 1 copy of the image, and still recover all data. \
A detailed explantion of raid levels, advantages, and disadvantages can be found
[here](https://www.booleanworld.com/raid-levels-explained/) and [here](https://linuxacademy.com/blog/linux/raid-explained/)
| Raid Level      | Min | FT  |
| --------------- | --- | --- |
| Raid-0 (Stripe) | 1   | 0   |
| Raid-1 (Mirror) | 2   | N-1 |
| Raid-4          | 3   | 1   |
| Raid-5          | 3   | 1   |
| Raid-6          | 4   | 2   |

## Choose a Size
During creation, the size will be determined by specifying the number of 4k blocks per disk image. \
The formula will look like this: `SIZE in GB = (4096*BLOCKCOUNT)/(1e9)` \
You can use any value for BLOCKCOUNT. See the table below for some examples.

| Block Count | Image Size | Formula                 |
| ----------- | ---------- | ----------------------- |
| 1000000     | 4.096 GB   | =(4096*1000000)/(1e9)   |
| 2000000     | 8.192 GB   | =(4096*2000000)/(1e9)   |
| 5000000     | 20.48 GB   | =(4096*5000000)/(1e9)   |
| 10000000    | 40.96 GB   | =(4096*10000000)/(1e9)  |
| 20000000    | 81.92 GB   | =(4096*20000000)/(1e9)  |
| 50000000    | 204.8 GB   | =(4096*50000000)/(1e9)  |
| 100000000   | 409.6 GB   | =(4096*100000000)/(1e9) |
| 200000000   | 819.2 GB   | =(4096*200000000)/(1e9) |

## Create
Next, choose a name and use the map to create a raid6 with 256k chunk size spanning 8 disk images. \
With a block count of 12000000, each image will be 49.152G (4k*12000000) of physical disk space. \
Total space taken up on disk 393.216G (parity + data) \
Total usable filesystem space 294.912G (available for data)
```bash
./mr_create.sh: <MAP> <RAIDNAME> <RAIDLEVEL> <NUMDEV> <CHUNKSIZE> <4k BLK CNT>

./mr_create.sh mnt_locations.map mynewraid 6 8 256 12000000
Creating Images: 8 * 49.152G each = 393.216G
Creating raid6 /dev/md/mynewraid: 294.912G
```

`cat /proc/mdstat` will show you the current resync status. \
`mdadm --detail /dev/md/mynewraid` will show you more detailed information about the raid device.
```bash
cat /proc/mdstat
md125 : active raid6 loop35[7] loop34[6] loop33[5] loop32[4] loop31[3] loop30[2] loop29[1] loop28[0]
      287797248 blocks super 1.2 level 6, 256k chunk, algorithm 2 [8/8] [UUUUUUUU]
      [=======>.............]  resync = 36.4% (17480284/47966208) finish=6.2min speed=81540K/sec
```

## Log File
After creation there will be a log file for your microraid: ${NAME}.log `cat mynewraid.log` \
At the end of the log you will find hints to help optimize your filesystem. \
Stride and stripe width are calculated based on raid chunk size and number of data-bearing images. \
If you choose raid1, you will not find hints. Strides and stripe widths are irrelevant on raid1.
```bash
cat mynewraid.log
./mr_create.sh mnt_locations.map mynewraid 6 8 256 12000000

dd if=/dev/zero of=/mnt/VAJ7LEPL/mynewraid/mynewraid.1.rimg bs=4096 count=0 seek=12000000
dd if=/dev/zero of=/mnt/VAJDDMHL/mynewraid/mynewraid.2.rimg bs=4096 count=0 seek=12000000
dd if=/dev/zero of=/mnt/VAJBPNDL/mynewraid/mynewraid.3.rimg bs=4096 count=0 seek=12000000
dd if=/dev/zero of=/mnt/VDG04BHK/mynewraid/mynewraid.4.rimg bs=4096 count=0 seek=12000000
dd if=/dev/zero of=/mnt/VAHJW81L/mynewraid/mynewraid.5.rimg bs=4096 count=0 seek=12000000
dd if=/dev/zero of=/mnt/VAJ0V17L/mynewraid/mynewraid.6.rimg bs=4096 count=0 seek=12000000
dd if=/dev/zero of=/mnt/VAHKY2ML/mynewraid/mynewraid.7.rimg bs=4096 count=0 seek=12000000
dd if=/dev/zero of=/mnt/VAHX5NWL/mynewraid/mynewraid.8.rimg bs=4096 count=0 seek=12000000

mdadm -C /dev/md/mynewraid -l 6 -n 8 -c 256 /dev/loop20 /dev/loop21 /dev/loop22 /dev/loop23 /dev/loop24 /dev/loop25 /dev/loop26 /dev/loop27

mynewraid.1.rimg: /dev/loop20
mynewraid.2.rimg: /dev/loop21
mynewraid.3.rimg: /dev/loop22
mynewraid.4.rimg: /dev/loop23
mynewraid.5.rimg: /dev/loop24
mynewraid.6.rimg: /dev/loop25
mynewraid.7.rimg: /dev/loop26
mynewraid.8.rimg: /dev/loop27

EXT4 Hints:
mkfs.ext4 -b 1024 -E stride=256,stripe_width=1536 /dev/md/mynewraid
mkfs.ext4 -b 4096 -E stride=64,stripe_width=384 /dev/md/mynewraid

XFS Hints:
mkfs.xfs -b size=1024  -d sunit=512,swidth=3072 /dev/md/mynewraid
mkfs.xfs -b size=2048  -d sunit=512,swidth=3072 /dev/md/mynewraid
mkfs.xfs -b size=4096  -d sunit=512,swidth=3072 /dev/md/mynewraid
mkfs.xfs -b size=8192  -d sunit=512,swidth=3072 /dev/md/mynewraid
mkfs.xfs -b size=16384 -d sunit=512,swidth=3072 /dev/md/mynewraid

BTRFS Hints:
mkfs.btrfs /dev/md/mynewraid
```

## Disk Images
These are the disk images that make up your new raid6 array.
```bash
ls -lh /mnt/*/mynewraid/*.rimg
-rw-r--r-- 1 root root 46G Apr 19 14:00 /mnt/VAHJW81L/mynewraid/mynewraid.5.rimg
-rw-r--r-- 1 root root 46G Apr 19 14:00 /mnt/VAHKY2ML/mynewraid/mynewraid.7.rimg
-rw-r--r-- 1 root root 46G Apr 19 14:00 /mnt/VAHX5NWL/mynewraid/mynewraid.8.rimg
-rw-r--r-- 1 root root 46G Apr 19 14:00 /mnt/VAJ0V17L/mynewraid/mynewraid.6.rimg
-rw-r--r-- 1 root root 46G Apr 19 14:00 /mnt/VAJ7LEPL/mynewraid/mynewraid.1.rimg
-rw-r--r-- 1 root root 46G Apr 19 14:00 /mnt/VAJBPNDL/mynewraid/mynewraid.3.rimg
-rw-r--r-- 1 root root 46G Apr 19 14:00 /mnt/VAJDDMHL/mynewraid/mynewraid.2.rimg
-rw-r--r-- 1 root root 46G Apr 19 14:00 /mnt/VDG04BHK/mynewraid/mynewraid.4.rimg
```

## Filesystem and Mounting
Create a filesystem on your new microraid and mount it. \
[More Information](https://github.com/Fullaxx/microraids/blob/master/MKFS_EXAMPLE.md) regarding filesystem creation. \
In most cases, I choose ext4 for my on-raid filesystem b/c of tools like zerofree and extundelete.
```bash
mkfs.ext4 -vv -b4096 -m0 -E stride=64,stripe_width=384 -O metadata_csum,64bit -T largefile4 /dev/md/mynewraid
mkdir /mnt/mynewraid
mount /dev/md/mynewraid /mnt/mynewraid
```

df will show you space available for use.
```bash
df -h /mnt/mynewraid
Filesystem      Size  Used Avail Use% Mounted on
/dev/md125      274G   65M  274G   1% /mnt/mynewraid
```
