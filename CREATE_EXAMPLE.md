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

## Choosing a Size
When creating a microraid, you will select the size by specifying the number of 4k blocks per disk image. \
The formula will look like this: `SIZE in GB = (4096*BLOCKCOUNT)/(1e9)` \
You can use any value for BLOCKCOUNT. See the table below for some examples.

| Block Count | Formula                 | Image Size |
| ----------- | ----------------------- | ---------- |
| 1000000     | =(4096*1000000)/(1e9)   | 4.096 GB   |
| 2000000     | =(4096*2000000)/(1e9)   | 8.192 GB   |
| 5000000     | =(4096*5000000)/(1e9)   | 20.48 GB   |
| 10000000    | =(4096*10000000)/(1e9)  | 40.96 GB   |
| 20000000    | =(4096*20000000)/(1e9)  | 81.92 GB   |
| 50000000    | =(4096*50000000)/(1e9)  | 204.8 GB   |
| 100000000   | =(4096*100000000)/(1e9) | 409.6 GB   |

## Create
Next, use the map to create a raid6 with 256k chunk size spanning 8 disk images. \
With a block count of 12000000, each image will be 49.152G (4k*12000000) of physical disk space. \
Total space taken up on disk 393.216G (parity + data) \
Total usable filesystem space 294.912G (available for data)
```bash
./mr_create.sh: <MAP> <RAIDNAME> <RAIDLEVEL> <NUMDEV> <CHUNKSIZE> <4k BLK CNT>

./mr_create.sh mnt_locations.map mynewraid 6 8 256 12000000
Creating Images: 8 * 49.152G each = 393.216G
Creating raid6 /dev/md/mynewraid: 294.912G
```

`cat /proc/mdstat` will show you the current resync status if you chose raid5 or raid6. \
`mdadm --detail /dev/md/mynewraid` will show you more detailed information about the raid device.
```bash
cat /proc/mdstat
md125 : active raid6 loop35[7] loop34[6] loop33[5] loop32[4] loop31[3] loop30[2] loop29[1] loop28[0]
      287797248 blocks super 1.2 level 6, 256k chunk, algorithm 2 [8/8] [UUUUUUUU]
      [=======>.............]  resync = 36.4% (17480284/47966208) finish=6.2min speed=81540K/sec
```

These are the disk images that make up your raid6 array
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
mkfs.ext4 -vv -b4096 -m0 -O metadata_csum,64bit -T largefile4 /dev/md/mynewraid
mkdir /mnt/mynewraid
mount /dev/md/mynewraid /mnt/mynewraid
```

df will show you space available for use.
```bash
df -h /mnt/mynewraid
Filesystem      Size  Used Avail Use% Mounted on
/dev/md125      274G   65M  274G   1% /mnt/mynewraid
```
