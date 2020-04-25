#!/bin/bash

usage()
{
  echo "$0: <MAP> <start|status>"
  exit 1
}

if [ "$#" -ne "2" ]; then usage; fi

if [ -r "$1" ]; then
  MAP="$1"
else
  usage
fi

case "$2" in
   start) CMD="start"  ;;
  status) CMD="status" ;;
       *) usage;;
esac

if [ `id -u` -ne "0" ]; then
  echo "Got Root?"
  exit 2
fi

BTFSBIN=`PATH="/sbin:/usr/sbin:$PATH" which btrfs`
if [ "$?" != "0" ]; then
  echo "btrfs not found!"
  exit 3
fi

while read -r LINE; do
  echo "FS:               ${LINE}"
  ${BTFSBIN} scrub ${CMD} ${LINE}
  echo
done < ${MAP}
