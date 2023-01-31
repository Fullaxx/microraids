#!/bin/bash

set -e

if [ `id -u` -ne "0" ]; then
  echo "Got Root?"
  exit 21
fi

LOBIN=`PATH="/sbin:/usr/sbin:$PATH" which losetup`
if [ "$?" != "0" ]; then
  echo "losetup not found!"
  exit 22
fi

MDBIN=`PATH="/sbin:/usr/sbin:$PATH" which mdadm`
if [ "$?" != "0" ]; then
  echo "mdadm not found!"
  exit 23
fi

# Loop all our images and create an array upon success
# The array of loop devices will be assembled into a raid device
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
# echo "Loop Devices: ${loop_array[@]}"

# Wait for the kernel to autodetect the raid on the loops
${MDBIN} --auto-detect
echo "Sleeping 3 seconds for kernel auto-detect ..."
sleep 3

# Determine raid device
FIRSTDEV=`basename ${loop_array[0]}`
NEWMD=`grep -w ${FIRSTDEV} /proc/mdstat | awk '{print $1}'`
if [ -z "${NEWMD}" ]; then
  echo "${FIRSTDEV} does not appear to be attached to a raid device!"
  exit 24
fi
echo "Found ${FIRSTDEV} on ${NEWMD}"
echo

# Check to see if the raid did not run clean
if ${MDBIN} --detail /dev/${NEWMD} | grep 'State :' | cut -d: -f2- | grep -qw inactive; then
  echo "/dev/${NEWMD} has been partially assembled, but did not run (state: inactive)"
  echo "You will have to run manually and troubleshoot:"
  echo "mdadm -R /dev/${NEWMD}"
  echo "mdadm --detail /dev/${NEWMD}"
  exit 25
fi

# Print raid info
echo -n "/dev/${NEWMD} has been assembled:"
${MDBIN} --detail /dev/${NEWMD} | grep 'State :' | cut -d: -f2-
grep -w ${NEWMD} /proc/mdstat

# Look for raid symlink under /dev/md/
if [ -d /dev/md ]; then
  for DEV in /dev/md/*; do
    RP=`realpath ${DEV}`
    if [ "${RP}" == "/dev/${NEWMD}" ]; then
      MRSYMLINK="${DEV}"
    fi
  done
fi

if [ -n "${MRSYMLINK}" ]; then
  echo "${MRSYMLINK} -> /dev/${NEWMD}"
fi

exit 0
