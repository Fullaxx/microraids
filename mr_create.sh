#!/bin/bash

# https://metebalci.com/blog/a-quick-tour-of-guid-partition-table-gpt/
# https://metebalci.com/blog/a-minimum-complete-tutorial-of-linux-ext4-file-system/
# https://tecadmin.net/working-with-array-bash-script/

set -e

if [ "$#" -ne "6" ]; then
  echo "$0: <MAP> <RAIDNAME> <RAIDLEVEL> <NUMDEV> <CHUNKSIZE> <4k BLK CNT>"
  exit 1
fi

if [ `id -u` -ne "0" ]; then
  echo "Got Root?"
  exit 2
fi

MAP="$1"
RAIDNAME="$2"
RL="$3"
NUMDEV="$4"
CHUNK="$5"
CNT="$6"
LOG="${RAIDNAME}.log"

BTOG="1000000000"
SRC="if=/dev/zero"
BS="4096"

if [ ! -r "${MAP}" ]; then
  echo "${MAP} is unreadable!"
  exit 3
fi

# Use the raid level to determine the number of missing and minumum disks
# This will be used for available space calculations
if [ "${RL}" == "6" ]; then   MD="2"; MIND="4"
elif [ "${RL}" == "5" ]; then MD="1"; MIND="3"
elif [ "${RL}" == "4" ]; then MD="1"; MIND="3"
elif [ "${RL}" == "1" ]; then MD="1"; MIND="2"
elif [ "${RL}" == "0" ]; then MD="0"; MIND="1"
else
  echo "RAID ${RL} is not supported!"
  exit 4
fi

if [ ${NUMDEV} -lt ${MIND} ]; then
  echo "${NUMDEV} is less than ${MIND}!"
  exit 5
fi

# Read in the MAP file into an array
# These will be the locations of our disk images
INDEX="0"
declare -a map_array
while read -r LINE; do
  map_array[${INDEX}]="${LINE}"
  INDEX=$(( INDEX+1 ))
done < ${MAP}
# echo "INDEX: ${INDEX}"

# Check to make sure we have the correct amount of locations
if [ "${INDEX}" != "${NUMDEV}" ]; then
  echo "The map has ${INDEX} locations and the raid has ${NUMDEV} devices!"
  echo "I need a map with exactly ${NUMDEV} locations!"
#  echo "INDEX(${INDEX}) != NUMDEV(${NUMDEV})"
  exit 6
fi

CALCBIN=`which calc`
if [ "$?" != "0" ]; then
  echo "calc not found!"
  exit 7
fi

LOBIN=`PATH="/sbin:/usr/sbin:$PATH" which losetup`
if [ "$?" != "0" ]; then
  echo "losetup not found!"
  exit 8
fi

MDBIN=`PATH="/sbin:/usr/sbin:$PATH" which mdadm`
if [ "$?" != "0" ]; then
  echo "mdadm not found!"
  exit 9
fi

IMGSIZE=`${CALCBIN} "${BS}*${CNT}" | awk '{print $1}'`
IMGSIZEG=`${CALCBIN} "${IMGSIZE}/${BTOG}" | awk '{print $1}'`
SPARSESIZEG=`${CALCBIN} "${NUMDEV}*${IMGSIZE}/${BTOG}" | awk '{print $1}'`
if [ "${RL}" == "1" ]; then
  BYTECOUNT=${IMGSIZE}
else
  BYTECOUNT=`${CALCBIN} "${IMGSIZE}*(${NUMDEV}-${MD})" | awk '{print $1}'`
fi
RAIDSIZEG=`${CALCBIN} "${BYTECOUNT}/${BTOG}" | awk '{print $1}'`

echo "Creating Images: ${NUMDEV} * ${IMGSIZEG}G each = ${SPARSESIZEG}G"
echo "Creating raid${RL} /dev/md/${RAIDNAME}: ${RAIDSIZEG}G [${BYTECOUNT} B]"
echo "Continue? (y/N)"
read ANS
echo

if [ "${ANS}" != "y" ] && [ "${ANS}" != "Y" ]; then
  echo "I will be here when you are ready to continue"
  exit 0
fi


# Use all the values provided to make our disk images
# While creating disk images, write out steps to our LOG file
# For each disk image, LOOP them with losetup so they can be assembled into a raid device
INDEX="0"
declare -a file_array
declare -a loop_array
echo "$0 $@" >> ${LOG}
echo >> ${LOG}
while [ ${INDEX} -ne ${NUMDEV} ]; do
  FILENUM=$(( INDEX+1 ))
  OUTF="${RAIDNAME}.${FILENUM}.rimg"
  BASEDIR=${map_array[${INDEX}]}
  if [ ! -d ${BASEDIR} ]; then echo "${BASEDIR} is not a dir!"; exit 1; fi
  NEXTDIR="${BASEDIR}/${RAIDNAME}"
  mkdir "${NEXTDIR}"
  if [ -e ${NEXTDIR}/${OUTF} ]; then echo "${NEXTDIR}/${OUTF} exists!"; exit 1; fi
  file_array[${INDEX}]="${OUTF}"
  if [ "${MR_CREATE_SPARSE}" == "no" ]; then
    dd ${SRC} of=${NEXTDIR}/${OUTF} bs=${BS} count=${CNT} 2>/dev/null
    echo "dd ${SRC} of=${NEXTDIR}/${OUTF} bs=${BS} count=${CNT}" >> ${LOG}
  else
    dd ${SRC} of=${NEXTDIR}/${OUTF} bs=${BS} count=0 seek=${CNT} 2>/dev/null
    echo "dd ${SRC} of=${NEXTDIR}/${OUTF} bs=${BS} count=0 seek=${CNT}" >> ${LOG}
  fi
  LOOPDEV=`${LOBIN} --find --show ${NEXTDIR}/${OUTF}`
  loop_array[${INDEX}]="${LOOPDEV}"
  INDEX=$(( INDEX+1 ))
done
echo >> ${LOG}

#echo ${file_array[@]}
#echo ${loop_array[@]}

# Make sure we dont give mdadm chunk arguments for a RAID 1
if [ "${RL}" != "1" ]; then
  CHUNKARG="-c ${CHUNK}"
else
  CHUNKARG=""
fi

# Assemble our raid device from the LOOP devices
${MDBIN} -C /dev/md/${RAIDNAME} --assume-clean -l ${RL} -n ${NUMDEV} ${CHUNKARG} ${loop_array[@]}
echo "mdadm -C /dev/md/${RAIDNAME} --assume-clean -l ${RL} -n ${NUMDEV} ${CHUNKARG} ${loop_array[@]}" >> ${LOG}
echo >> ${LOG}
echo "/dev/md/${RAIDNAME} is ready!"

# Update the log file
INDEX="0"
while [ ${INDEX} -ne ${NUMDEV} ]; do
  echo "${file_array[${INDEX}]}: ${loop_array[${INDEX}]}" >> ${LOG}
  INDEX=$(( INDEX+1 ))
done

# If raid1, FS hints would be irrelevant
if [ "${RL}" == "1" ]; then
  exit 0
fi

# https://gryzli.info/2015/02/26/calculating-filesystem-stride_size-and-stripe_width-for-best-performance-under-raid/
# Stride size = [RAID chunk size] / [Filesystem block size]
# Stripe width = [Stride size] * [Number of data-bearing disks]
echo >> ${LOG}
echo "EXT4 Hints:" >> ${LOG}

STRIDE=`${CALCBIN} "${CHUNK}/1" | awk '{print $1}'`
SWIDTH=`${CALCBIN} "${STRIDE}*(${NUMDEV}-${MD})" | awk '{print $1}'`
echo "mkfs.ext4 -b 1024 -E stride=${STRIDE},stripe_width=${SWIDTH} /dev/md/${RAIDNAME}" >> ${LOG}

STRIDE=`${CALCBIN} "${CHUNK}/4" | awk '{print $1}'`
SWIDTH=`${CALCBIN} "${STRIDE}*(${NUMDEV}-${MD})" | awk '{print $1}'`
echo "mkfs.ext4 -b 4096 -E stride=${STRIDE},stripe_width=${SWIDTH} /dev/md/${RAIDNAME}" >> ${LOG}

# https://erikugel.wordpress.com/tag/btrfs/
# https://www.mythtv.org/wiki/Optimizing_Performance#Optimizing_XFS_on_RAID_Arrays
echo >> ${LOG}
echo "XFS Hints:" >> ${LOG}
SUNIT=`${CALCBIN} "(${CHUNK}*1024)/512" | awk '{print $1}'`
SWIDTH=`${CALCBIN} "${SUNIT}*(${NUMDEV}-${MD})" | awk '{print $1}'`
echo "mkfs.xfs -b size=1024  -d sunit=${SUNIT},swidth=${SWIDTH} /dev/md/${RAIDNAME}" >> ${LOG}
echo "mkfs.xfs -b size=2048  -d sunit=${SUNIT},swidth=${SWIDTH} /dev/md/${RAIDNAME}" >> ${LOG}
echo "mkfs.xfs -b size=4096  -d sunit=${SUNIT},swidth=${SWIDTH} /dev/md/${RAIDNAME}" >> ${LOG}
echo "mkfs.xfs -b size=8192  -d sunit=${SUNIT},swidth=${SWIDTH} /dev/md/${RAIDNAME}" >> ${LOG}
echo "mkfs.xfs -b size=16384 -d sunit=${SUNIT},swidth=${SWIDTH} /dev/md/${RAIDNAME}" >> ${LOG}

# Does btrfs read this automatically?
echo >> ${LOG}
echo "BTRFS Hints:" >> ${LOG}
echo "mkfs.btrfs /dev/md/${RAIDNAME}" >> ${LOG}
