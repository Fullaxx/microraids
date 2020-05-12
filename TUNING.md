## Raid Speed Limit
The speed limit values here reflect the speed targets of the resync process during periods of inactivity. \
These values here are per-disk (not per-array) and are in units of Kibibytes per second. 
[Source](https://www.cyberciti.biz/tips/linux-raid-increase-resync-rebuild-speed.html)
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

## Stripe Cache Size
This will set the amount of memory available for the stripe cache. \
This value is in units of Kibibytes and must be between 17 and 32768. \
`memory_consumed = system_page_size * nr_disks * stripe_cache_size` 
[Source](https://www.cyberciti.biz/tips/linux-raid-increase-resync-rebuild-speed.html)
| Value | # | Formula      | Memory   |
| ----- | - | ------------ | -------- |
|  1024 | 4 | =(4\*4\*1024)  |   16 MiB |
|  2048 | 4 | =(4\*4\*2048)  |   32 MiB |
|  4096 | 4 | =(4\*4\*4096)  |   64 MiB |
|  8192 | 4 | =(4\*4\*8192)  |  128 MiB |
| 16384 | 4 | =(4\*4\*16384) |  256 MiB |
| 32768 | 4 | =(4\*4\*32768) |  512 MiB |
|  1024 | 8 | =(4\*8\*1024)  |   32 MiB |
|  2048 | 8 | =(4\*8\*2048)  |   64 MiB |
|  4096 | 8 | =(4\*8\*4096)  |  128 MiB |
|  8192 | 8 | =(4\*8\*8192)  |  256 MiB |
| 16384 | 8 | =(4\*8\*16384) |  512 MiB |
| 32768 | 8 | =(4\*8\*32768) | 1024 MiB |
```bash
./tuning/stripe_cache_size.sh: <get> <raid>
./tuning/stripe_cache_size.sh: <set> <raid> [size]

./tuning/stripe_cache_size.sh get md127
256

./tuning/stripe_cache_size.sh set md127 16384

./tuning/stripe_cache_size.sh get md127
16384
```
