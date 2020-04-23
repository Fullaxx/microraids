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

LOBIN=`PATH="/sbin:/usr/sbin:$PATH" which losetup`
if [ "$?" != "0" ]; then
  echo "losetup not found!"
  exit 4
fi

echo "Searching for ${NAME} ..."

# Make sure that none of the loop device are still assembled in any raid device
# We want to make sure they are completely dormant before we detach them
INDEX="0"
RAIDCOUNT="0"
declare -a loop_array
while read -r LINE; do
  if [ ! -d ${LINE}/${NAME} ]; then
    echo "${LINE}/${NAME} is not a directory!"; exit 5
  fi
  DIMG=`ls -1 ${LINE}/${NAME}/${NAME}.?.rimg`

# Surround this with IF block so we don't bail early due to a missing image when array is degraded
  if ${LOBIN} -a | grep -qw ${DIMG}; then
    ${LOBIN} -a | grep -w ${DIMG}
    LOOP=`${LOBIN} -a | grep -w ${DIMG} | cut -d: -f1`
  else
    LOOP=""
  fi

  if [ -n "${LOOP}" ]; then
    loop_array[${INDEX}]="${LOOP}"
    BN=`basename ${LOOP}`
    RD=`grep ${BN} /proc/mdstat | awk '{print $1}'`
    if [ -n "${RD}" ] ; then
      echo "${LOOP} appears to be attached to ${RD}..."
      RAIDCOUNT=$(( RAIDCOUNT + 1))
    fi
    INDEX=$(( INDEX+1 ))
  fi
done < ${MAP}
echo

# If INDEX equals 0, we found no loop devices related to ${NAME}
# If ${NAME} is not active, we could exit 0 here?
if [ "${INDEX}" == "0" ]; then
  echo "${NAME} does not appear to be active"
  exit 6
fi

# RAIDCOUNT should equal zero b/c the raid should have been dismantled by now
if [ "${RAIDCOUNT}" != "0" ]; then
  echo "RAID appears to be active, Cowardly refusing to continue!"
  exit 7
fi

# echo "${loop_array[@]}"
for LOOP in ${loop_array[@]}; do
  echo "Detaching ${LOOP} ..."
  ${LOBIN} -d ${LOOP}
done
