## List Your Microraids
mr_list.sh will give you a listing of all your microraids, given a map file.
```bash
./mr_list.sh: <MAP>

./mr_list.sh mnt_locations.map
mynewraid
mydata
mymirror
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
