btrfs will by default checksum your data blocks. \
Using the scrub feature, we can validate that there are no problems with any data blocks currently storing data. \
To validate a single filesystem, do the following
```
btrfs scrub start /mnt/VAHAW81L
btrfs scrub status /mnt/VAHAW81L
```

If you have a microraids map file, you can use the provided scrub script to check all your filesystems.
```
./scrub.sh start mnt_locations.map
./scrub.sh status mnt_locations.map
```

For each filesystem, it will give you relevant status.
```
Scrub started:    Tue Apr 14 12:53:58 2020
Status:           finished
Duration:         0:00:00
Total to scrub:   512.00KiB
Rate:             170.67KiB/s
Error summary:    no errors found
```
