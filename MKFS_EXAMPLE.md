## Examples of how to create different filesystems

### [BTRFS](https://wiki.archlinux.org/index.php/Btrfs)
Create a btrfs filesystem on partition ${PART} with label ${LABEL}
```
mkfs.btrfs -L ${LABEL} ${PART}
```

The btrfs default blocksize is 16KB. To use a larger blocksize for data/metadata specify a value for the nodesize via the -n switch as shown in this example using 16KB blocks:
```
mkfs.btrfs -L ${LABEL} -n 16k ${PART}
```

### [EXT4](https://wiki.archlinux.org/index.php/ext4)
Create an ext4 filesystem on new raid ${RAIDDEV} with label ${LABEL} while doing a read-write bad blocks check
```
mkfs.ext4 -vv -b4096 -cc -m0 -O metadata_csum,64bit -L ${LABEL} ${RAIDDEV}
```

Create an ext4 filesystem on new raid ${RAIDDEV} with label ${LABEL} while doing a read-only bad blocks check
```
mkfs.ext4 -vv -b4096 -c -m0 -O metadata_csum,64bit -L ${LABEL} ${RAIDDEV}
```

If you need to adjust your [bytes-per-inode ratio](https://wiki.archlinux.org/index.php/ext4#Bytes-per-inode_ratio), use -T to specify a usage-type
```
mkfs.ext4 -vv -b4096 -m0 -O metadata_csum,64bit -T largefile  -L ${LABEL} ${RAIDDEV}
mkfs.ext4 -vv -b4096 -m0 -O metadata_csum,64bit -T largefile4 -L ${LABEL} ${RAIDDEV}
```

## Tuning EXT4
Ext4 has 3 types of journal modes: Journal, Ordered, and Writeback. \
Adjust your ext4 filesystem using one of the following commands. \
Only run tune2fs while the filesystem is unmounted.
```
Set Journal Mode: tune2fs -O has_journal -o journal_data ${RAIDDEV}
Set Ordered Mode: tune2fs -O has_journal -o journal_data_ordered ${RAIDDEV}
Set Writeback Mode: tune2fs -O has_journal -o journal_data_writeback ${RAIDDEV}
```
Enable directory indexing with the following command. \
Only run tune2fs/e2fsck while the filesystem is unmounted.
```
tune2fs -O dir_index ${RAIDDEV}
e2fsck -D ${RAIDDEV}
```

### [XFS](https://wiki.archlinux.org/index.php/XFS)
Create an xfs filesystem on new raid ${RAIDDEV} with label ${LABEL}
```
mkfs.xfs -L ${LABEL} ${RAIDDEV}
```
