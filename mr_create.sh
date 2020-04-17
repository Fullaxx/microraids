#!/bin/bash

# https://metebalci.com/blog/a-quick-tour-of-guid-partition-table-gpt/
# https://metebalci.com/blog/a-minimum-complete-tutorial-of-linux-ext4-file-system/
# https://tecadmin.net/working-with-array-bash-script/

set -e

if [ "$#" -ne "6" ]; then
  echo "$0: <RAIDNAME> <RAIDLEVEL> <NUMDEV> <CHUNKSIZE> <4k BLK CNT> <MAP>"
  exit 1
fi

if [ `id -u` -ne "0" ]; then
  echo "Got Root?"
  exit 2
fi

RAIDNAME="$1"
RL="$2"
NUMDEV="$3"
CHUNK="$4"
CNT="$5"
MAP="$6"
LOG="${RAIDNAME}.log"

BTOG="1000000000"
SRC="if=/dev/zero"
BS="4096"

if [ "${RL}" == "6" ]; then
  MD="2"
elif [ "${RL}" == "5" ]; then
  MD="1"
elif [ "${RL}" == "1" ]; then
  MD="1"
elif [ "${RL}" == "0" ]; then
  MD="0"
else
  MD="0"
  echo "RL: ${RL} Unsupported!"
  exit 3
fi

if [ ! -r "${MAP}" ]; then
  echo "${MAP} is unreadable!"
  exit 4
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
  echo "INDEX(${INDEX}) != NUMDEV(${NUMDEV})"
  exit 5
fi

CALCBIN=`which calc`
if [ "$?" != "0" ]; then
  echo "Couldnt find calc!"
  exit 6
fi

LOBIN=`PATH="/sbin:$PATH" which losetup`
if [ "$?" != "0" ]; then
  echo "Couldnt find losetup!"
  exit 7
fi

MDBIN=`PATH="/sbin:$PATH" which mdadm`
if [ "$?" != "0" ]; then
  echo "Couldnt find mdadm!"
  exit 8
fi

IMGSIZE=`${CALCBIN} "${BS}*${CNT}" | awk '{print $1}'`
IMGSIZEG=`${CALCBIN} "${IMGSIZE}/${BTOG}" | awk '{print $1}'`
SPARSESIZEG=`${CALCBIN} "${NUMDEV}*${IMGSIZE}/${BTOG}" | awk '{print $1}'`
BYTECOUNT=`${CALCBIN} "${IMGSIZE}*(${NUMDEV}-${MD})" | awk '{print $1}'`
RAIDSIZEG=`${CALCBIN} "${BYTECOUNT}/${BTOG}" | awk '{print $1}'`

echo "Creating Images: ${NUMDEV} * ${IMGSIZEG}G each = ${SPARSESIZEG}G"
echo "Creating raid${RL} /dev/md/${RAIDNAME}: ${RAIDSIZEG}G [${BYTECOUNT} B]"
echo "Continue? (y/N)"
read ANS
echo

# Why can't I use -a here on ubuntu??
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
  dd ${SRC} of=${NEXTDIR}/${OUTF} bs=${BS} count=0 seek=${CNT} 2>/dev/null
  echo "dd ${SRC} of=${NEXTDIR}/${OUTF} bs=${BS} count=0 seek=${CNT}" >> ${LOG}
  LOOPDEV=`${LOBIN} --find --show ${NEXTDIR}/${OUTF}`
  loop_array[${INDEX}]="${LOOPDEV}"
  INDEX=$(( INDEX+1 ))
done
echo >> ${LOG}

echo ${file_array[@]}
echo ${loop_array[@]}

# Assemble our raid device from the LOOP devices
${MDBIN} -C /dev/md/${RAIDNAME} -l ${RL} -n ${NUMDEV} -c ${CHUNK} ${loop_array[@]}
echo "mdadm -C /dev/md/${RAIDNAME} -l ${RL} -n ${NUMDEV} -c ${CHUNK} ${loop_array[@]}" >> ${LOG}
echo >> ${LOG}
echo "/dev/md/${RAIDNAME} is ready!"

# Update the log file
INDEX="0"
while [ ${INDEX} -ne ${NUMDEV} ]; do
  echo "${file_array[${INDEX}]}: ${loop_array[${INDEX}]}" >> ${LOG}
  INDEX=$(( INDEX+1 ))
done
