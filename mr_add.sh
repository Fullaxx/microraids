#!/bin/bash

set -e

if [ "$#" -ne "4" ]; then
  echo "$0: <MAP> <NAME> <RAIDDEV> <DIMG>"
  exit 1
fi

MAP="$1"
NAME="$2"
RAIDDEV="$3"
NEWDIMG="$4"

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

if [ ! -f ${NEWDIMG} ]; then
  echo "${NEWDIMG} is not a file!"
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

echo "Attaching ${NEWDIMG} ..."
NEWLOOP=`${LOBIN} --find --show ${NEWDIMG}`
${MDBIN} ${RAIDDEV} --add-spare ${NEWLOOP}
