#!/bin/bash

SCRIPTDIR=`dirname $0`
INFOSCRIPT="${SCRIPTDIR}/mr_info.sh"
REMOVESCRIPT="${SCRIPTDIR}/mr_remove.sh"
ADDSCRIPT="${SCRIPTDIR}/mr_add.sh"
set -e

if [ "$#" -ne "4" ]; then
  echo "$0: <MAP> <NAME> <RAIDDEV> <FILE|LOOP>"
  exit 1
fi

MAP="$1"
NAME="$2"
RAIDDEV="$3"

if [ `id -u` -ne "0" ]; then
  echo "Got Root?"
  exit 2
fi

if [ ! -r ${MAP} ]; then
  echo "${MAP} is not readable!"
  exit 3
fi

if [ ! -b ${RAIDDEV} ]; then
  echo "${RAIDDEV} is not a block device!"
  exit 4
fi

MDBIN=`PATH="/sbin:/usr/sbin:$PATH" which mdadm`
if [ "$?" != "0" ]; then
  echo "mdadm not found!"
  exit 5
fi

LOBIN=`PATH="/sbin:/usr/sbin:$PATH" which losetup`
if [ "$?" != "0" ]; then
  echo "losetup not found!"
  exit 6
fi

CALCBIN=`which calc`
if [ "$?" != "0" ]; then
  echo "calc not found!"
  exit 7
fi

RTYPE=`${MDBIN} --detail ${RAIDDEV} | grep 'Raid Level : ' | awk '{print $4}'`
case "${RTYPE}" in
  raid1) echo "${RAIDDEV} is ${RTYPE}";;
  raid4) echo "${RAIDDEV} is ${RTYPE}";;
  raid5) echo "${RAIDDEV} is ${RTYPE}";;
  raid6) echo "${RAIDDEV} is ${RTYPE}";;
      *) echo "${RTYPE} not supported!"; exit 8;;
esac

if [ -b "$4" ]; then
  LOOP="$4"
  FDIMG=`${LOBIN} -a | grep -w ${LOOP} | cut -d\( -f2 | cut -d\) -f1`
elif [ -f "$4" ]; then
  FDIMG="$4"
  LOOP=`${LOBIN} -a | grep -w ${FDIMG} | cut -d: -f1`
else
  echo "I dont know what to do with $4"
  exit 9
fi
if [ ! -b "${LOOP}" ]; then
  echo "${LOOP} is not a block device!"
  exit 10
fi

if [ ! -r "${FDIMG}" ]; then
  echo "${FDIMG} is not readable!"
  exit 11
fi

# Validate that ${FDIMG} belongs to ${NAME}
if ! ${INFOSCRIPT} ${MAP} ${NAME} | grep -qw ${FDIMG}; then
  echo "${FDIMG} does not belong to ${NAME}!"
  exit 12
fi

echo "Replacing Faulty Disk Image: ${FDIMG} (${LOOP}) ..."
echo "Continue? (y/N)"
read ANS
echo

# Why can't I use -a here on ubuntu??
if [ "${ANS}" != "y" ] && [ "${ANS}" != "Y" ]; then
  echo "Patiently awaiting your orders."
  exit 0
fi

${REMOVESCRIPT} ${MAP} ${NAME} ${RAIDDEV} ${LOOP}
echo

BS="4096"
BYTES=`ls -l ${FDIMG} | awk '{print $5}' | sort -u | head -n1`
BLOCKS=`${CALCBIN} "${BYTES}/${BS}" | awk '{print $1}'`
mv ${FDIMG} ${FDIMG}.bad

# When creating a replacement image on the same disk as a faulty image
# We will default to writing zeros to our new file to validate sectors
# If you trust the new sectors and are ok with doing validation during recovery
# You can adjust the default behavior with the env variable MR_REPLACE_VALIDATION="quick"
if [ "${MR_REPLACE_VALIDATION}" == "quick" ]; then
  echo "Creating new disk image: ${FDIMG} (Sector Validation DISABLED) ..."
  dd if=/dev/zero of=${FDIMG} bs=${BS} count=0 seek=${BLOCKS}
else
  echo "Creating new disk image: ${FDIMG} (Sector Validation Enabled) ..."
  dd if=/dev/zero of=${FDIMG} bs=${BS} count=${BLOCKS}
fi

echo
${ADDSCRIPT} ${MAP} ${NAME} ${RAIDDEV} ${FDIMG}
