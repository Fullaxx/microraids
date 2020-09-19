#!/bin/bash

set -e

if [ "$#" -ne "1" ]; then
  echo "$0: <RAIDDEV>"
  exit 1
fi

RAIDDEV="$1"

if [ `id -u` -ne "0" ]; then
  echo "Got Root?"
  exit 2
fi

if [ -L ${RAIDDEV} ]; then
  MD=`readlink ${RAIDDEV} | cut -d/ -f2`
elif [ -b ${RAIDDEV} ]; then
  MD=`basename ${RAIDDEV}`
elif [ -b /dev/${RAIDDEV} ]; then
  MD="${RAIDDEV}"
else
  echo "I dont know what to do with ${RAIDDEV}!"
  exit 3
fi

if ! grep "^${MD} : " /proc/mdstat; then
  echo "Did not find ${RAIDDEV} in /proc/mdstat"
fi

SA="/sys/block/${MD}/md/sync_action"
if [ -f ${SA} ]; then
  echo "Sending check to ${SA} ..."
  echo "check" > ${SA}
else
  echo "${SA} not found!"
  exit 4
fi
