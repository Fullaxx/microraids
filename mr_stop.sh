#!/bin/bash

SCRIPTDIR=`dirname $0`
DETACHSCRIPT="${SCRIPTDIR}/mr_detach.sh"
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

LOBIN=`PATH="/sbin:/usr/sbin:$PATH" which losetup`
if [ "$?" != "0" ]; then
  echo "losetup not found!"
  exit 4
fi

MDBIN=`PATH="/sbin:/usr/sbin:$PATH" which mdadm`
if [ "$?" != "0" ]; then
  echo "mdadm not found!"
  exit 5
fi

if [ ! -x ${DETACHSCRIPT} ]; then
  echo "${DETACHSCRIPT} is not executable!"
  exit 6
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
    exit 7
  fi
  dimg_array[${INDEX}]="${DIMG}"
  LOOP=`${LOBIN} -a | grep -w ${DIMG} | cut -d: -f1`
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
  echo "${NAME} has no loops active"
  exit 0
fi

# If the LOOP is greater than the DIMG count, we have a problem
# LOOP count can be less, in the case of a degraded array
if [ "${#loop_array[@]}" -gt "${#dimg_array[@]}" ]; then
  echo "Expected ${#dimg_array[@]} loop devices, found ${#loop_array[@]}!"
  exit 8
fi

# If we have no active raid, we can skip to detach.sh
if [ "${#raid_array[@]}" == "0" ]; then
  echo "${NAME} has no assembled raid, jumping to detach"
  ${DETACHSCRIPT} ${MAP} ${NAME}
  exit $?
fi

# Check to make sure we are about to stop the correct raid device
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

# if our raid device is mounted, DO NOT try and stop the raid
if mount | grep -q ${RAIDDEV}; then
  echo "${RAIDDEV} appears to be mounted!"
  exit 11
fi

# Whew, we finally got here
echo "Stopping ${RAIDDEV} ..."
${MDBIN} -S ${RAIDDEV}
echo

${DETACHSCRIPT} ${MAP} ${NAME}
