#!/bin/bash

list_all()
{
  MAP="$1"
  INDEX="0"
  declare -a loc_array
  while read -r LINE; do
    loc_array[${INDEX}]="${LINE}"
    INDEX=$(( INDEX+1 ))
  done < ${MAP}

  if [ "${#loc_array[@]}" == "0" ]; then
    echo "${MAP} has no locations"
    exit 0
  fi

  MRCOUNT=`echo "${loc_array[@]}" | xargs -n1 ls -1 | sort -u | wc -l`
  if [ "${MRCOUNT}" == "0" ]; then
    echo "Found 0 microraids"
    exit 0
  fi
  echo "Found ${MRCOUNT} microraids:"
  echo "${loc_array[@]}" | xargs -n1 ls -1 | sort -u
}

mr_info()
{
  MAP="$1"
  NAME="$2"
  INDEX="0"
  RAIDCOUNT="0"
  declare -a dimg_array
  declare -a loop_array
  declare -a raid_array
  while read -r LINE; do
    DIMG=`ls -1 ${LINE}/${NAME}/${NAME}.?.rimg`
    if [ ! -r "${DIMG}" ]; then
      echo "Could not find disk images for ${NAME} using this map!"
      exit 7
    fi
    dimg_array[${INDEX}]="${DIMG}"
    LOOP=`${LOBIN} -a | grep -w ${DIMG} | cut -d: -f1`
    if [ -n "${LOOP}" ]; then
      loop_array[${INDEX}]="${LOOP}"
      BN=`basename ${LOOP}`
      RD=`grep -w ${BN} /proc/mdstat | awk '{print $1}'`
      if [ -n "${RD}" ]; then
        raid_array[${INDEX}]="${RD}"
      fi
    fi
    INDEX=$(( INDEX+1 ))
  done < ${MAP}

#echo "dimg_array: ${dimg_array[@]}"
#echo "loop_array: ${loop_array[@]}"
#echo "raid_array: ${raid_array[@]}"
#echo "INDEX: ${INDEX}"

  echo "Found ${#dimg_array[@]} disk images for ${NAME}:"
  for DI in ${dimg_array[@]}; do
    USED=`du -sh ${DI} | awk '{print $1}'`
    AVAIL=`du -sh --apparent-size ${DI} | awk '{print $1}'`
    BYTES=`du -b ${DI} | awk '{print $1}'`
    BLKCOUNT=`${CALCBIN} "${BYTES}/4096" | awk '{print $1}'`
    echo "${DI} (${USED}/${AVAIL}) [${BLKCOUNT} 4k-blocks]"
  done
  echo

# If ${NAME} has no loops, we are done here
  if [ "${#loop_array[@]}" == "0" ]; then
    echo "${NAME} has no loops active"
    exit 0
  fi

  echo "Found ${#loop_array[@]} loops active for ${NAME}:"
  for LOOP in ${loop_array[@]}; do
    DI=`${LOBIN} -a | grep -w ${LOOP} | cut -d\( -f2 | cut -d\) -f1`
    echo -n "${LOOP}: ${DI}"; echo
  done
  echo

  if [ "${#raid_array[@]}" == "0" ]; then
    echo "${NAME} has no assembled raid"
    exit 0
  fi

# Check to make sure we are about to stop the correct raid device
  UNIQUERAIDCOUNT=`echo "${raid_array[@]}" | xargs -n1 echo | sort -u | wc -l`
  if [ "${UNIQUERAIDCOUNT}" != "1" ]; then
    echo "${NAME} appears to be attached to multiple devices?"
    echo "${raid_array[@]}"
    exit 8
  fi

# Does ${NAME} have a named raid device?
  RAIDNAME="0"
  RAIDDEV="/dev/${raid_array[0]}"
  for DEV in /dev/md/*; do
    RP=`realpath ${DEV}`
    if [ "${RP}" == "${RAIDDEV}" ]; then
      RAIDNAME="${DEV}"
    fi
  done

  if [ "${RAIDNAME}" != "0" ]; then
    echo "${NAME} appears to be assembled into ${RAIDNAME} (${RAIDDEV})"
  else
    echo "${NAME} appears to be assembled into ${RAIDDEV}"
  fi
  echo -n "${raid_array[0]} :"
  ${MDBIN} --detail ${RAIDDEV} | grep 'State :' | cut -d: -f2-
  grep -A1 -w "${raid_array[0]}" /proc/mdstat

  if mount | grep -qw ${raid_array[0]}; then
    echo
    echo "${NAME} appears to be mounted: "
    mount | grep ${raid_array[0]}
    echo
    df -h /dev/${raid_array[0]}
  fi
}

if [ -z "$1" ]; then
  echo "$0: <MAP> [NAME]"
  exit 1
fi

MAP="$1"

if [ -n "$2" ]; then
  NAME="$2"
fi

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

MDBIN=`PATH="/sbin:/usr/sbin:$PATH" which mdadm`
if [ "$?" != "0" ]; then
  echo "mdadm not found!"
  exit 5
fi

CALCBIN=`which calc`
if [ "$?" != "0" ]; then
  echo "calc not found!"
  exit 6
fi

# Place this after all the which commands
# So that which does trigger an exit w/o error message
set -e

if [ "$#" == "1" ]; then
  list_all "${MAP}"
elif [ "$#" == "2" ]; then
  mr_info "${MAP}" "${NAME}"
fi
