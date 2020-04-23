#!/bin/bash

SCRIPTDIR=`dirname $0`
REMOVESCRIPT="${SCRIPTDIR}/mr_remove.sh"
ADDSCRIPT="${SCRIPTDIR}/mr_add.sh"
set -e

if [ "$#" -ne "4" ]; then
  echo "$0: <MAP> <NAME> <RAIDDEV> [FILE|LOOP]"
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

LOBIN=`PATH="/sbin:/usr/sbin:$PATH" which losetup`
if [ "$?" != "0" ]; then
  echo "losetup not found!"
  exit 5
fi

if [ -b "$4" ]; then
  LOOP="$4"
  FDIMG=`${LOBIN} -a | grep -w ${LOOP} | cut -d\( -f2 | cut -d\) -f1`
elif [ -f "$4" ]; then
  FDIMG="$4"
  LOOP=`${LOBIN} -a | grep -w ${FDIMG} | cut -d: -f1`
else
  echo "I dont know what to do with $4"
  exit 6
fi

if [ ! -b "${LOOP}" ]; then
  echo "${LOOP} is not a block device!"
  exit 7
fi

if [ ! -r "${FDIMG}" ]; then
  echo "${FDIMG} is not readable!"
  exit 8
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
BYTES=`ls -l ${FDIMG} | awk '{print $5}' | sort -u | head -n1`
mv ${FDIMG} ${FDIMG}.bad
#dd if=/dev/zero of=${FDLOC}/${FDIMG} bs=4096 count=0 seek=1024
#dd if=/dev/zero of=${FDLOC}/${FDIMG} bs=1 count=0 seek=4194304
echo "Creating new disk image: ${FDIMG}"
dd if=/dev/zero of=${FDIMG} bs=1 count=${BYTES}
echo

${ADDSCRIPT} ${MAP} ${NAME} ${RAIDDEV} ${FDIMG}
