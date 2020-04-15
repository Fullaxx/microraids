#!/bin/bash

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

LOBIN=`PATH="/sbin:$PATH" which losetup`
if [ "$?" != "0" ]; then
  echo "losetup not found!"
  exit 4
fi

echo "Searching for ${NAME} ..."; echo

INDEX="0"
RAIDCOUNT="0"
declare -a loop_array
while read -r LINE; do
  RIMG=${LINE}/${NAME}/${NAME}.?.rimg
  losetup -a | grep ${RIMG}
  LOOP=`losetup -a | grep ${RIMG} | cut -d: -f1`
  if [ -n "${LOOP}" ]; then
    loop_array[${INDEX}]="${LOOP}"
    BN=`basename ${LOOP}`
    RD=`grep ${BN} /proc/mdstat | cut -d: -f1`
    if [ -n "${RD}" ] ; then
      echo "${LOOP} appears to be attached to ${RD}..."
      RAIDCOUNT=$(( RAIDCOUNT + 1))
    fi
    INDEX=$(( INDEX+1 ))
  fi
done < ${MAP}

if [ "${INDEX}" == "0" ]; then
  echo "${NAME} does not appear to be in use"
  exit 4
fi

# RAIDCOUNT should equal zero b/c the raid should have been dismantled by now
if [ "${RAIDCOUNT}" != "0" ]; then
  echo; echo "Cowardly refusing to continue!"
  exit 5
fi

echo; echo -n "Detach the Loops? (y/N): "
read ANS

# Why can't I use -a here on ubuntu??
if [ "${ANS}" != "y" ] && [ "${ANS}" != "Y" ]; then
  echo "I will not touch your precious loops."
  exit 0
fi

# echo "${loop_array[@]}"
for LOOP in ${loop_array[@]}; do
  echo "Detaching ${LOOP} ..."
  ${LOBIN} -d ${LOOP}
done
