### Stop Your Microraid
If you have just gone through the Create Example, you should have a running microraid. \
Before we continue, make sure to umount it, if it is currently mounted. \
`umount /dev/md/mynewraid` or `umount /mnt/mynewraid` should do the trick. \
Once the microraid is unmounted, you can stop it using the mr_stop.sh script. \
You will need to provide 2 argurment to mr_stop.sh: the name of your microraid and the map file. \
If all goes well, it will ask you if you want to "detach the loops". Press y and Enter. \
```
./mr_stop.sh: <NAME> <MAP>

./mr_stop.sh mynewraid mnt_locations.map

TODO GIVE EXAMPLE OUTPUT HERE
```

### Run Your Microraid
To run your microraid after it has been stopped, use the mr_start.sh script. \
You will need to provide 2 argurments to mr_start.sh: the name of your microraid and the map file.
```
./mr_start.sh: <NAME> <MAP>

./mr_start.sh mynewraid mnt_locations.map

TODO GIVE EXAMPLE OUTPUT HERE
```
