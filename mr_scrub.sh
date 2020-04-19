#!/bin/bash

usage()
{
  echo "$0: <start|status> <MAP>"
  exit 1
}

if [ "$#" -ne "2" ]; then usage; fi

case "$1" in
   start) CMD="start"  ;;
  status) CMD="status" ;;
       *) usage;;
esac

if [ -r "$2" ]; then
  MAP="$2"
else
  usage
fi

if [ `id -u` -ne "0" ]; then
  echo "Got Root?"
  exit 2
fi

BTFSBIN=`PATH="/sbin:/usr/sbin:$PATH" which btrfs`
if [ "$?" != "0" ]; then
  echo "Couldnt find btrfs!"
  exit 3
fi

while read -r LINE; do
  echo "FS:               ${LINE}"
  ${BTFSBIN} scrub ${CMD} ${LINE}
  echo
done < ${MAP}
