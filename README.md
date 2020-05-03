# microraids
Fighting BITROT and URE with every last breath

### Overview
I have always been a huge proponent of typical RAID. 
Back in the day of 2TB drives, disks were quite reliable. 
Even when a disk failed, I never had a problem doing a RAID recovery/resync onto a new disk. 
The RAID would keep running for days or weeks no problem even with 1 disk missing, 
up until the point a new disk could be inserted and replace the bad disk. 
From that perspective, the RAID system was very reliable. 
Fast-Forward to today where 8TB drives are ubiquitous and the probability 
of doing a RAID5 recovery a 9x8TB array is between [0.3% and 56.2%](http://www.raid-failure.com/raid5-failure.aspx). 
I had to learn about URE percentages the hard way, so here we are. \
I propose that the fundamentals of RAID are still good (including the software), 
but doing a full recovery on a LARGE array is no longer a realistic option 
given the bit error rates of current drives (i.e. RAID5 on a 72TB array). 
I choose to make many small "microraids" to encapsulate my data. 
This will keep the recovery percentages very high for each array. 
Each microraid is backed by a set of disk images, placed anywhere on any disk. 
For each microraid you can choose a different level of redundancy, 
even though they are stored on the same set of physical disks. 
microraids gives the flexibility to have any number of RAID 0/1/4/5/6 arrays as long as available drive space will allow it. 
Also each microraid can be checked independently for integrity and consistency in multiple ways. 

### Advantages
* Disk capacities do not have to match
* Integrity issues can be identified before recovery
* Recovery probabilities are significantly increased
* You can put multiple raid types (i.e. 0/1/4/5/6) on the same disk

### Required Software
* [calc](https://sourceforge.net/projects/calc/)
* Standard Utilities: sgdisk / hdparm / dd / losetup / mdadm

### HOWTO
* Step 1: [Prepare your physical disks](https://github.com/Fullaxx/microraids/blob/master/PREPARE_EXAMPLE.md)
* Step 2: [Create your microraid](https://github.com/Fullaxx/microraids/blob/master/CREATE_EXAMPLE.md)
* Step 3: [Start/Stop your microraid](https://github.com/Fullaxx/microraids/blob/master/STOP_START_EXAMPLE.md)
* Step 4: [Check your microraid](https://github.com/Fullaxx/microraids/blob/master/CHECK_EXAMPLE.md)
* Step 5: [Replace a faulty image](https://github.com/Fullaxx/microraids/blob/master/REPLACE_EXAMPLE.md)

### Tested Operating Systems
* [RapidLinux](https://github.com/Fullaxx/RapidLinux)
* [Slackware](http://www.slackware.com/)
* [Ubuntu](https://ubuntu.com/)

### Simple Mini-ITX Setup
* [Cooler Master Elite 110](https://www.coolermaster.com/catalog/cases/mini-itx/elite110/)
* [ASRock J4105B-ITX](https://www.asrock.com/mb/Intel/J4105B-ITX/index.us.asp)
* [Ableconn PEX-SA130](https://www.amazon.com/dp/B07595M2MK)
  - ASM1062 chipset supports 2x Port Multiplier
* 2x [Mediasonic ProBox HF2-SU3S2](https://www.amazon.com/dp/B003X26VV4)
  - Each ProBox connects 4x 3.5" drives of any size via eSATA
* 8x [4TB HGST Ultrastar 7K4000 REFURB](https://www.amazon.com/dp/B0856WZT3B/)
  - Chosen to show software reliability/recovery on very inexpensive hardware

### Alternate Hardware
* [SYBA SI-PEX40072](https://www.sybausa.com/index.php?route=product/product&product_id=155)
  - This Marvell Chipset also supports 2x Port Multiplier

### More Information
* [bitrot and atomic cows](https://arstechnica.com/information-technology/2014/01/bitrot-and-atomic-cows-inside-next-gen-filesystems/)
* [Raid Rebuild Probability Calc](http://www.raid-failure.com/raid5-failure.aspx)
* [URE in RAID](http://www.raidtips.com/raid5-ure.aspx)
* [RAID questions](https://superuser.com/questions/1288587/btrfs-raid5-or-raid6-for-data-storage)
