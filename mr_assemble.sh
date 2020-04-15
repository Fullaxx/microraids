#!/bin/bash

set -e

if [ `id -u` -ne "0" ]; then
  echo "Got Root?"
  exit 1
fi

LOBIN=`PATH="/sbin:$PATH" which losetup`
if [ "$?" != "0" ]; then
  echo "losetup not found!"
  exit 2
fi

MDBIN=`PATH="/sbin:$PATH" which mdadm`
if [ "$?" != "0" ]; then
  echo "mdadm not found!"
  exit 3
fi

INDEX="0"
declare -a loop_array
while [ -n "$1" ]; do
  LOOPDEV=`${LOBIN} --find --show $1`
  echo "$1: ${LOOPDEV}"
  loop_array[${INDEX}]="${LOOPDEV}"
  INDEX=$(( INDEX+1 ))
  shift
done

echo
echo "Loop Devices: ${loop_array[@]}"

# Wait for the kernel to autodetect the raid on the loops
sleep 2

FIRSTDEV=`basename ${loop_array[0]}`
NEWRAID=`cat /proc/mdstat | grep ${FIRSTDEV} | awk '{print $1}'`
if [ -n "${NEWRAID}" ]; then
  for DEV in /dev/md/*; do
    RP=`realpath ${DEV}`
    if [ "$RP" == "/dev/${NEWRAID}" ]; then
      echo "${DEV} is ready!"
      exit 0
    fi
  done
fi

# DEVICE NOT FOUND
echo "No new raid devices found under /dev/md/"
exit 9
