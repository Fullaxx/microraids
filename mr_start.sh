#!/bin/bash

SCRIPTDIR=`dirname $0`
ASSEMBLESCRIPT="${SCRIPTDIR}/mr_assemble.sh"
set -e

usage()
{
  echo "$0: <MAP> <NAME>"
  exit 1
}

if [ "$#" -ne "2" ]; then usage; fi

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

if [ ! -x ${ASSEMBLESCRIPT} ]; then
  echo "${ASSEMBLESCRIPT} is not executable!"
  exit 4
fi

if [ -b /dev/md/${NAME} ]; then
  echo "/dev/md/${NAME} exists!"
  exit 5
fi

LOBIN=`PATH="/sbin:/usr/sbin:$PATH" which losetup`
if [ "$?" != "0" ]; then
  echo "losetup not found!"
  exit 6
fi

# For each mount location in the map file
# Find the disk image that corresponds to the requested microraid ${NAME}
INDEX="0"
declare -a dimg_array
while read -r LINE; do
  if [ ! -d ${LINE}/${NAME} ]; then
    echo "${LINE}/${NAME} is not a directory!"; exit 7
  fi
  DIMG=`ls -1 ${LINE}/${NAME}/${NAME}.?.rimg`
  if [ -z "${DIMG}" ]; then
    echo "${LINE}/${NAME}/${NAME}.?.rimg does not exist!"; exit 8
  fi
  if [ ! -r ${DIMG} ]; then
    echo "${DIMG} is not readable!"; exit 9
  fi
  if ${LOBIN} -a | grep -qw ${DIMG}; then
    echo "${DIMG} appears to be looped already!"; exit 10
  fi
  dimg_array[${INDEX}]="${DIMG}"
  INDEX=$(( INDEX+1 ))
done < ${MAP}

# Assemble all these images into a RAID device
${ASSEMBLESCRIPT} ${dimg_array[@]}
exit $?
