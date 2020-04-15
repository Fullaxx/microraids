#!/bin/bash

SCRIPTDIR=`dirname $0`
ASSEMBLESCRIPT="${SCRIPTDIR}/mr_assemble.sh"
set -e

usage()
{
  echo "$0: <NAME> <MAP>"
  exit 1
}

if [ "$#" -ne "2" ]; then usage; fi

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

if [ ! -x ${ASSEMBLESCRIPT} ]; then
  echo "${ASSEMBLESCRIPT} is not executable!"
  exit 4
fi

if [ -b /dev/md/${NAME} ]; then
  echo "/dev/md/${NAME} exists!"
  exit 5
fi

INDEX="0"
declare -a rimg_array
while read -r LINE; do
  RIMG=${LINE}/${NAME}/${NAME}.?.rimg
  if [ -r ${RIMG} ]; then 
    rimg_array[${INDEX}]="${RIMG}"
  else
    echo "${RIMG} is not readable!"; exit 6
  fi
  INDEX=$(( INDEX+1 ))
done < ${MAP}

# Assemble all these images into a RAID device
${ASSEMBLESCRIPT} ${rimg_array[@]}

if [ ! -b /dev/md/*${NAME} ]; then
  echo "Could not find block device for ${NAME}"
  exit 6
fi
