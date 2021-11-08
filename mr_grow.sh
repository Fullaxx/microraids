#!/bin/bash

SCRIPTDIR=`dirname $0`
ASSEMBLESCRIPT="${SCRIPTDIR}/mr_assemble.sh"
set -e

usage()
{
  echo "$0: <MAP> <NAME> <4k BLK CNT>"
  exit 1
}

if [ "$#" -ne "3" ]; then usage; fi

MAP="$1"
NAME="$2"
CNT="$3"

if [ `id -u` -ne "0" ]; then
  echo "Got Root?"
  exit 2
fi

if [ ! -r ${MAP} ]; then
  echo "${MAP} is not readable!"
  exit 3
fi

if [ ! -x ${ASSEMBLESCRIPT} ]; then
  echo "${ASSEMBLESCRIPT} is not executable!"
  exit 4
fi

if [ -b /dev/md/${NAME} ]; then
  echo "/dev/md/${NAME} exists!"
  exit 5
fi

LOBIN=`PATH="/sbin:/usr/sbin:$PATH" which losetup`
if [ "$?" != "0" ]; then
  echo "losetup not found!"
  exit 6
fi

MDBIN=`PATH="/sbin:/usr/sbin:$PATH" which mdadm`
if [ "$?" != "0" ]; then
  echo "mdadm not found!"
  exit 7
fi

CALCBIN=`which calc`
if [ "$?" != "0" ]; then
  echo "calc not found!"
  exit 8
fi

# For each mount location in the map file
# Find the disk image that corresponds to the requested microraid ${NAME}
INDEX="0"
declare -a dimg_array
while read -r LINE; do
  if [ ! -d ${LINE}/${NAME} ]; then
    echo "${LINE}/${NAME} is not a directory!"; exit 9
  fi
  DIMG=`ls -1 ${LINE}/${NAME}/${NAME}.?.rimg`
  if [ -z "${DIMG}" ]; then
    echo "${LINE}/${NAME}/${NAME}.?.rimg does not exist!"; exit 10
  fi
  if [ ! -r ${DIMG} ]; then
    echo "${DIMG} is not readable!"; exit 11
  fi
  if ${LOBIN} -a | grep -qw ${DIMG}; then
    echo "${DIMG} appears to be looped already!"; exit 12
  fi
  dimg_array[${INDEX}]="${DIMG}"
  INDEX=$(( INDEX+1 ))
done < ${MAP}

BS="4096"
BYTES=`ls -l ${dimg_array[0]} | awk '{print $5}' | sort -u | head -n1`
BLOCKS=`${CALCBIN} "${BYTES}/${BS}" | awk '{print $1}'`

if [ ${CNT} -lt ${BLOCKS} ]; then
  echo "New image size must be greater than current image size (${CNT} < ${BLOCKS})"
  exit 13
fi

if [ "${CNT}" == "${BLOCKS}" ]; then
  echo "New image size must be greater than current image size (${CNT} == ${BLOCKS})"
  exit 14
fi

for IMG in ${dimg_array[@]}; do
  echo "Increasing ${IMG} to ${CNT} 4k-blocks ..."
  dd if=/dev/zero of=${IMG} bs=${BS} count=0 seek=${CNT} status=none
done
echo

# Assemble all these images into a RAID device
TMPFILE="/tmp/MRGROW.$$"
${ASSEMBLESCRIPT} ${dimg_array[@]} | tee ${TMPFILE}
RAIDDEV=`cat ${TMPFILE} | grep 'has been assembled: clean' | awk '{print $1}'`
rm -f ${TMPFILE}
echo

# https://documentation.suse.com/sles/12-SP4/html/SLES-all/cha-raid-resize.html
# --assume-clean
# The array uses any space that has been added to the devices, but this space will not be synchronized.
# This is recommended for RAID 1 because the synchronization is not needed.
# It can be useful for other RAID levels if the space that was added to the member devices was pre-zeroed.

${MDBIN} -G ${RAIDDEV} -z max --assume-clean
${MDBIN} -D ${RAIDDEV} | grep -e "Array Size" -e "Dev Size"
echo

echo "You may now resize your FS"
echo "EXT4 HINT   : e2fsck -f -y ${RAIDDEV} && resize2fs ${RAIDDEV}"
echo "REISER HINT : resize_reiserfs ${RAIDDEV}"
echo "XFS HINT    : mount ${RAIDDEV} /mnt/MOUNTPOINT; xfs_growfs -d /mnt/MOUNTPOINT"
echo "BTRFS HINT  : mount ${RAIDDEV} /mnt/MOUNTPOINT; btrfs filesystem resize max /mnt/MOUNTPOINT"
