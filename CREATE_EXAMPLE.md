First, create your locataions map. This is a txt file that tells the create script where to place each disk image. \
I have 8 disks, so I have 8 locations. Each image will be on a seperate physical disk.
```
cat mnt_locations.map
/mnt/PAGXKNDT
/mnt/PCG4XHRB
/mnt/PAJXH1LT
/mnt/PAKY5VGT
/mnt/PBG0XTDT
/mnt/PBG0YBUT
/mnt/PBGAS33T
/mnt/PBG0W71T
```

Next, use the map to create a raid6 with 8 disk images. \
Each image will be 49.152G (4k*12000000) of physical disk space \
Total space taken up on disk 393.216G (parity + data) \
Total useable filesystem space 294.912G (available for data)
```
./create.sh: <RAIDNAME> <RAIDLEVEL> <NUMDEV> <CHUNKSIZE> <4k BLK CNT> <MAP>

./create.sh mynewraid 6 8 256 12000000 mnt_locations.map
Creating Images: 8 * 49.152G each = 393.216G
Creating raid6 /dev/md/mynewraid: 294.912G
```

/proc/mdstat will show you the current resync status if you chose raid5 or raid6
```
cat /proc/mdstat
md125 : active raid6 loop35[7] loop34[6] loop33[5] loop32[4] loop31[3] loop30[2] loop29[1] loop28[0]
      287797248 blocks super 1.2 level 6, 256k chunk, algorithm 2 [8/8] [UUUUUUUU]
      [=======>.............]  resync = 36.4% (17480284/47966208) finish=6.2min speed=81540K/sec
```

These are the disk images that make up your raid6 array
```
ls -lh /mnt/*/mynewraid/*.rimg
-rw-r--r-- 1 root root 46G Apr 12 17:41 /mnt/PAGXKNDT/mynewraid/mynewraid.1.rimg
-rw-r--r-- 1 root root 46G Apr 12 17:41 /mnt/PAJXH1LT/mynewraid/mynewraid.3.rimg
-rw-r--r-- 1 root root 46G Apr 12 17:41 /mnt/PAKY5VGT/mynewraid/mynewraid.4.rimg
-rw-r--r-- 1 root root 46G Apr 12 17:41 /mnt/PBG0W71T/mynewraid/mynewraid.8.rimg
-rw-r--r-- 1 root root 46G Apr 12 17:41 /mnt/PBG0XTDT/mynewraid/mynewraid.5.rimg
-rw-r--r-- 1 root root 46G Apr 12 17:41 /mnt/PBG0YBUT/mynewraid/mynewraid.6.rimg
-rw-r--r-- 1 root root 46G Apr 12 17:41 /mnt/PBGAS33T/mynewraid/mynewraid.7.rimg
-rw-r--r-- 1 root root 46G Apr 12 17:41 /mnt/PCG4XHRB/mynewraid/mynewraid.2.rimg
```

Create a filesystem and mount it
```
mkfs.ext4 -vv -b4096 -m0 -O metadata_csum,64bit -T largefile4 /dev/md/mynewraid
mkdir /mnt/mynewraid
mount /dev/md/mynewraid /mnt/mynewraid
```

df will show you space available
```
df -h /mnt/mynewraid
Filesystem      Size  Used Avail Use% Mounted on
/dev/md125      274G   65M  274G   1% /mnt/mynewraid
```
