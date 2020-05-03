## List Your Microraids
mr_info.sh will give you a listing of all your microraids, given a map file.
```bash
./mr_info.sh: <MAP> [NAME]

./mr_info.sh mnt_locations.map
mynewraid
mydata
neo
```

## Microraid In Detail
mr_info.sh will give you detailed information, given a map file and a name.
```bash
./mr_info.sh: <MAP> [NAME]

./mr_info.sh mnt_locations.map neo
Found 8 disk images for neo:
/mnt/PAGXKNDT/neo/neo.1.rimg
/mnt/PCG4XHRB/neo/neo.2.rimg
/mnt/PAJXH1LT/neo/neo.3.rimg
/mnt/PAKY5VGT/neo/neo.4.rimg
/mnt/PBG0XTDT/neo/neo.5.rimg
/mnt/PBG0YBUT/neo/neo.6.rimg
/mnt/PBGAS33T/neo/neo.7.rimg
/mnt/PBG0W71T/neo/neo.8.rimg

Found 8 loops active for neo:
/dev/loop12: (/mnt/PAGXKNDT/neo/neo.1.rimg)
/dev/loop13: (/mnt/PCG4XHRB/neo/neo.2.rimg)
/dev/loop14: (/mnt/PAJXH1LT/neo/neo.3.rimg)
/dev/loop15: (/mnt/PAKY5VGT/neo/neo.4.rimg)
/dev/loop16: (/mnt/PBG0XTDT/neo/neo.5.rimg)
/dev/loop17: (/mnt/PBG0YBUT/neo/neo.6.rimg)
/dev/loop18: (/mnt/PBGAS33T/neo/neo.7.rimg)
/dev/loop19: (/mnt/PBG0W71T/neo/neo.8.rimg)

neo appears to be assembled into /dev/md/neo (/dev/md127)
```

## Stop Your Microraid
If you have just gone through the [Create Example](https://github.com/Fullaxx/microraids/blob/master/CREATE_EXAMPLE.md), you should have a running microraid. \
If it is currently mounted, make sure to umount it. \
`umount /dev/md/mynewraid` or `umount /mnt/mynewraid` should do the trick. \
Once the microraid is unmounted, you can stop it using the mr_stop.sh script. \
You will need to provide 2 argurments to mr_stop.sh: the map file and the name of your microraid.
```bash
./mr_stop.sh: <MAP> <NAME>

./mr_stop.sh mnt_locations.map mynewraid

TODO GIVE EXAMPLE OUTPUT HERE
```

## Start Your Microraid
To run your microraid after it has been stopped, use the mr_start.sh script. \
You will need to provide 2 argurments to mr_start.sh: the map file and the name of your microraid.
```bash
./mr_start.sh: <MAP> <NAME>

./mr_start.sh mnt_locations.map mynewraid

TODO GIVE EXAMPLE OUTPUT HERE
```
