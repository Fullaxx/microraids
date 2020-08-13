## Grow Your Microraid
mr_grow.sh allow you to grow your microraid. \
If it is currently started, make sure to stop it. \
The mdadm tool supports resizing only for software RAID levels 1, 4, 5, and 6.
```bash
./mr_grow.sh: <MAP> <NAME> <4k BLK CNT>

./mr_grow.sh 4T.map resizetest 2700000
Increasing /mnt/PAGXKNDT/resizetest/resizetest.1.rimg to 2700000 4k-blocks ...
Increasing /mnt/PCG4XHRB/resizetest/resizetest.2.rimg to 2700000 4k-blocks ...
Increasing /mnt/PAJXH1LT/resizetest/resizetest.3.rimg to 2700000 4k-blocks ...
Increasing /mnt/PAKY5VGT/resizetest/resizetest.4.rimg to 2700000 4k-blocks ...
Increasing /mnt/PBG0XTDT/resizetest/resizetest.5.rimg to 2700000 4k-blocks ...
Increasing /mnt/PBG0YBUT/resizetest/resizetest.6.rimg to 2700000 4k-blocks ...
Increasing /mnt/PBGAS33T/resizetest/resizetest.7.rimg to 2700000 4k-blocks ...
Increasing /mnt/PBG0W71T/resizetest/resizetest.8.rimg to 2700000 4k-blocks ...

/mnt/PAGXKNDT/resizetest/resizetest.1.rimg: /dev/loop20
/mnt/PCG4XHRB/resizetest/resizetest.2.rimg: /dev/loop21
/mnt/PAJXH1LT/resizetest/resizetest.3.rimg: /dev/loop22
/mnt/PAKY5VGT/resizetest/resizetest.4.rimg: /dev/loop23
/mnt/PBG0XTDT/resizetest/resizetest.5.rimg: /dev/loop24
/mnt/PBG0YBUT/resizetest/resizetest.6.rimg: /dev/loop25
/mnt/PBGAS33T/resizetest/resizetest.7.rimg: /dev/loop26
/mnt/PBG0W71T/resizetest/resizetest.8.rimg: /dev/loop27

Sleeping 3 seconds for kernel auto-detect ...

/dev/md126 has been assembled: clean 
md126 : active raid5 loop27[8] loop26[6] loop25[5] loop24[4] loop23[3] loop22[2] loop21[1] loop20[0]
/dev/md/resizetest -> /dev/md126

mdadm: component size of /dev/md126 has been set to 10796928K
        Array Size : 75578496 (72.08 GiB 77.39 GB)
     Used Dev Size : 10796928 (10.30 GiB 11.06 GB)

You may now resize your FS
```
