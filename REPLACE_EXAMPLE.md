## Fix Your Microraid
If you find that one of your disk images has bad blocks or is corrupt in some way, \
You can recreate your disk image using the mr_replace.sh script. \
*NOTE* RAID-0 has no parity, you cannot recover/recreate any disk images in a RAID-0 array. \
This script takes 4 arguments: the map, the name, the raid device and either the bad file or loop. \
In the first example we will give it the corrupt file.
```bash
./mr_replace.sh: <MAP> <NAME> <RAIDDEV> <FILE|LOOP>

./mr_replace.sh: 8T.map test /dev/md/test /mnt/VAJDDMHL/test/test.2.rimg
/dev/md/test is raid5
Replacing Faulty Disk Image: /mnt/VAJDDMHL/test/test.2.rimg (/dev/loop13) ...
Continue? (y/N)
y

mdadm: set /dev/loop13 faulty in /dev/md/test
mdadm: hot removed /dev/loop13 from /dev/md/test
Detaching /dev/loop13 ...

Creating new disk image: /mnt/VAJDDMHL/test/test.2.rimg
10000+0 records in
10000+0 records out
40960000 bytes (41 MB, 39 MiB) copied, 0.102778 s, 399 MB/s

Attaching /mnt/VAJDDMHL/test/test.2.rimg ...
mdadm: added /dev/loop13
```

In the second example, we will give it a loop device.
```bash
./mr_replace.sh: <MAP> <NAME> <RAIDDEV> <FILE|LOOP>

./mr_replace.sh: 8T.map test /dev/md/test /dev/loop14
/dev/md/test is raid5
Replacing Faulty Disk Image: /mnt/VAJBPNDL/test/test.3.rimg (/dev/loop14) ...
Continue? (y/N)
y

mdadm: set /dev/loop14 faulty in /dev/md/test
mdadm: hot removed /dev/loop14 from /dev/md/test
Detaching /dev/loop14 ...

Creating new disk image: /mnt/VAJBPNDL/test/test.3.rimg
10000+0 records in
10000+0 records out
40960000 bytes (41 MB, 39 MiB) copied, 0.102542 s, 399 MB/s

Attaching /mnt/VAJBPNDL/test/test.3.rimg ...
mdadm: added /dev/loop14
```

## Verify Your Microraid
mr_info.sh will give you a detailed view of your microraid, given a map file and a name.
```bash
./mr_info.sh: <MAP> [NAME]

./mr_info.sh 8T.map test
Found 8 disk images for test:
/mnt/VAJ7LEPL/test/test.1.rimg
/mnt/VAJDDMHL/test/test.2.rimg
/mnt/VAJBPNDL/test/test.3.rimg
/mnt/VDG04BHK/test/test.4.rimg
/mnt/VAHJW81L/test/test.5.rimg
/mnt/VAJ0V17L/test/test.6.rimg
/mnt/VAHKY2ML/test/test.7.rimg
/mnt/VAHX5NWL/test/test.8.rimg

Found 8 loops active for test:
/dev/loop12: /mnt/VAJ7LEPL/test/test.1.rimg
/dev/loop13: /mnt/VAJDDMHL/test/test.2.rimg
/dev/loop14: /mnt/VAJBPNDL/test/test.3.rimg
/dev/loop15: /mnt/VDG04BHK/test/test.4.rimg
/dev/loop16: /mnt/VAHJW81L/test/test.5.rimg
/dev/loop17: /mnt/VAJ0V17L/test/test.6.rimg
/dev/loop18: /mnt/VAHKY2ML/test/test.7.rimg
/dev/loop19: /mnt/VAHX5NWL/test/test.8.rimg

test appears to be assembled into /dev/md/test (/dev/md127)
md127 : active raid5 loop14[11] loop13[10] loop12[9] loop19[8] loop18[6] loop17[5] loop16[4] loop15[3]
      272832 blocks super 1.2 level 5, 64k chunk, algorithm 2 [8/8] [UUUUUUUU]
```
