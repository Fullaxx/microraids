#!/bin/bash

usage()
{
  echo "$0: <get> <raid>"
  echo "$0: <set> <raid> [size]"
  exit 1
}

if [ "$#" -lt 2 ]; then usage; fi

if [ `id -u` -ne "0" ]; then
  echo "Got Root?"
  exit 2
fi

if [ -b "$2" ]; then
  RP=`realpath $2`
  MD=`basename ${RP}`
else
  MD="$2"
fi

PARAM="/sys/block/${MD}/md/stripe_cache_size"
if [ ! -f ${PARAM} ]; then
  echo "${PARAM} does not exist!"
  exit 3
fi

case "$1" in
  get) cat ${PARAM}; exit 0 ;;
  set) SIZE="$3" ;;
    *) usage;;
esac

if [ -z "${SIZE}" ]; then usage; fi

# Valid values are 17 to 32768
if [ "${SIZE}" -lt 17 ] || [ "${SIZE}" -gt 32768 ]; then
  echo "Size must be between 17 - 32768!"
  exit 4
fi

echo "${SIZE}" > ${PARAM}
