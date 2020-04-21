#!/bin/bash

set -e

if [ "$#" -ne "2" ]; then
  echo "$0: <MAP> <NAME>"
  exit 1
fi

MAP="$1"
NAME="$2"

if [ `id -u` -ne "0" ]; then
  echo "Got Root?"
  exit 2
fi

if [ ! -r ${MAP} ]; then
  echo "${MAP} is not readable!"
  exit 3
fi

MDBIN=`PATH="/sbin:/usr/sbin:$PATH" which mdadm`
if [ "$?" != "0" ]; then
  echo "mdadm not found!"
  exit 4
fi

# Walk through each disk image, finding loop devices and raid device (if active)
INDEX="0"
declare -a dimg_array
declare -a loop_array
declare -a raid_array
while read -r LINE; do
  DIMG=`ls -1 ${LINE}/${NAME}/${NAME}.?.rimg`
  if [ ! -r "${DIMG}" ]; then
    echo "Could not find disk images for ${NAME} using this map!"
    exit 5
  fi
  dimg_array[${INDEX}]="${DIMG}"
  LOOP=`losetup -a | grep ${DIMG} | cut -d: -f1`
  if [ -n "${LOOP}" ]; then
    loop_array[${INDEX}]="${LOOP}"
    BN=`basename ${LOOP}`
    RD=`grep -w ${BN} /proc/mdstat | awk '{print $1}'`
    if [ -n "${RD}" ]; then
      raid_array[${INDEX}]="${RD}"
    fi
  fi
  INDEX=$(( INDEX+1 ))
done < ${MAP}

# echo "dimg_array: ${dimg_array[@]}"
# echo "loop_array: ${loop_array[@]}"
# echo "raid_array: ${raid_array[@]}"
# echo "INDEX: ${INDEX}"

# If ${NAME} has no loops, we are done here
if [ "${#loop_array[@]}" == "0" ]; then
  echo "${NAME} has no loops active!"
  exit 6
fi

# If the LOOP count doesn't match the DIMG count, we have a problem
if [ "${#loop_array[@]}" != "${#dimg_array[@]}" ]; then
  echo "Expected ${#dimg_array[@]} loop devices, only found ${#loop_array[@]}!"
  exit 7
fi

# If we have no active raid, we cannot get detailed information
if [ "${#raid_array[@]}" == "0" ]; then
  echo "${NAME} has no assembled raid!"
  exit 8
fi

# Check to make sure we are about to detail the correct raid device
UNIQUERAIDCOUNT=`echo "${raid_array[@]}" | xargs -n1 echo | sort -u | wc -l`
if [ "${UNIQUERAIDCOUNT}" != "1" ]; then
  echo "${NAME} appears to be attached to multiple devices?"
  echo "${raid_array[@]}"
  exit 9
fi

MD=${raid_array[0]}
RAIDDEV="/dev/${MD}"
if [ ! -b ${RAIDDEV} ]; then
  echo "${RAIDDEV} is not a block device!"
  exit 10
fi

# Whew, we finally got here
${MDBIN} --detail ${RAIDDEV}
