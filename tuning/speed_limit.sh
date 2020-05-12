#!/bin/bash

usage()
{
  echo "$0: <get> <min|max>"
  echo "$0: <set> <min|max> [limit]"
  exit 1
}

if [ "$#" -lt 2 ]; then usage; fi

if [ `id -u` -ne "0" ]; then
  echo "Got Root?"
  exit 2
fi

PARAM="/proc/sys/dev/raid/speed_limit_$2"
if [ ! -f ${PARAM} ]; then
  echo "${PARAM} does not exist!"
  exit 3
fi

case "$1" in
  get) VAL=`cat ${PARAM}`; echo "${VAL} KiB/s"; exit 0 ;;
  set) LIMIT="$3" ;;
    *) usage;;
esac

if [ -z "${LIMIT}" ]; then usage; fi

echo "${LIMIT}" > ${PARAM}
