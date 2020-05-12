## Raid Speed Limit
The speed limit values here reflect the speed targets of the resync process during periods of inactivity. \
These values here are per-disk (not per-array) and are in units of Kibibytes per second. 
[More Info](https://www.cyberciti.biz/tips/linux-raid-increase-resync-rebuild-speed.html)
```bash
./tuning/speed_limit.sh: <get> <min|max>
./tuning/speed_limit.sh: <set> <min|max> [limit]

./tuning/speed_limit.sh get min
1000 KiB/s

./tuning/speed_limit.sh get max
200000 KiB/s

./tuning/speed_limit.sh set min 30000
./tuning/speed_limit.sh set max 250000

./tuning/speed_limit.sh get min
30000 KiB/s

./tuning/speed_limit.sh get max
250000 KiB/s
```

