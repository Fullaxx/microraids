#!/bin/bash

set -e

if [ `id -u` -ne "0" ]; then
  echo "Got Root?"
  exit 1
fi

LOBIN=`PATH="/sbin:/usr/sbin:$PATH" which losetup`
if [ "$?" != "0" ]; then
  echo "losetup not found!"
  exit 2
fi

MDBIN=`PATH="/sbin:/usr/sbin:$PATH" which mdadm`
if [ "$?" != "0" ]; then
  echo "mdadm not found!"
  exit 3
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
echo "Sleeping 2 seconds for kernel auto-detect ..."
sleep 2
echo

# Look for new raid device under /dev/md/
FIRSTDEV=`basename ${loop_array[0]}`
NEWRAID=`grep -w ${FIRSTDEV} /proc/mdstat | awk '{print $1}'`

if [ -z "${NEWRAID}" ]; then
  echo "${FIRSTDEV} does not appear to be attached to a raid device!"
  exit 4
fi

if ${MDBIN} --detail /dev/${NEWRAID} | grep 'State :' | cut -d: -f2- | grep -qw inactive; then
  echo "/dev/${NEWRAID} has been partially assembled, but did not run (state: inactive)"
  echo "You will have to run manually and troubleshoot:"
  echo "mdadm -R /dev/${NEWRAID}"
  echo "mdadm --detail /dev/${NEWRAID}"
  exit 5
fi

#RAIDCOUNT=`ls -1 /dev/md/ 2>/dev/null | wc -l`
#if [ "${RAIDCOUNT}" == "0" ]; then
#  echo "No raid devices found under /dev/md/"
#  echo "${NEWRAID} did not assemble correctly!"
#  echo "If your array is degraded, you might have to run manually:"
#  echo "mdadm -R /dev/${NEWRAID} ${loop_array[@]}"
#  echo "mdadm --detail /dev/${NEWRAID}"
#  exit 10
#fi

for DEV in /dev/md/*; do
  RP=`realpath ${DEV}`
  if [ "${RP}" == "/dev/${NEWRAID}" ]; then
    grep ${NEWRAID} /proc/mdstat
    echo "${DEV} is ready!"
    echo -n "State:"
    ${MDBIN} --detail /dev/${NEWRAID} | grep 'State :' | cut -d: -f2-
    exit 0
  fi
done

# We couldn't find the named raid device?
echo "raid device not found under /dev/md/"
exit 6
