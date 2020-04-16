#!/bin/bash

SCRIPTDIR=`dirname $0`
DETACHSCRIPT="${SCRIPTDIR}/mr_detach.sh"
set -e

if [ "$#" -ne "2" ]; then
  echo "$0: <NAME> <MAP>"
  exit 1
fi

NAME="$1"
MAP="$2"

if [ `id -u` -ne "0" ]; then
  echo "Got Root?"
  exit 2
fi

if [ ! -r ${MAP} ]; then
  echo "${MAP} is not readable!"
  exit 3
fi

MDBIN=`PATH="/sbin:$PATH" which mdadm`
if [ "$?" != "0" ]; then
  echo "mdadm not found!"
  exit 4
fi

if [ ! -x ${DETACHSCRIPT} ]; then
  echo "${DETACHSCRIPT} is not executable!"
  exit 5
fi

# Walk through each disk image and find the raid device that is in use
INDEX="0"
while read -r LINE; do
  RIMG=${LINE}/${NAME}/${NAME}.?.rimg
  LOOP=`losetup -a | grep ${RIMG} | cut -d: -f1`
  if [ -n "${LOOP}" ]; then
    BN=`basename ${LOOP}`
    RD=`grep ${BN} /proc/mdstat | cut -d: -f1`

    if [ "${INDEX}" == "0" ]; then
      MD="${RD}"
    elif [ "${RD}" != "${MD}" ]; then
      echo "${RD} does not match ${MD}!"; exit 6
    fi
    INDEX=$(( INDEX+1 ))
  fi
done < ${MAP}

if [ "${INDEX}" == "0" ]; then
  echo "${NAME} does not appear to be in use"
  exit 7
fi

RAIDDEV="/dev/${MD}"
if [ ! -b ${RAIDDEV} ]; then
  echo "${RAIDDEV} is not a block device!"
  exit 8
fi

if mount | grep -q ${RAIDDEV}; then
  echo "${RAIDDEV} appears to be mounted!"
  exit 9
fi

echo "Stopping ${RAIDDEV} ..."
${MDBIN} -S ${RAIDDEV}
echo

${DETACHSCRIPT} ${NAME} ${MAP}
