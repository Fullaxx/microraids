#!/bin/bash

usage()
{
  echo "$0: <none> <raid>"
  echo "$0: <internal> <raid>"
  exit 1
}

if [ "$#" -ne 2 ]; then usage; fi

if [ `id -u` -ne "0" ]; then
  echo "Got Root?"
  exit 2
fi

if [ -L $2 ]; then
  MD=`readlink $2 | cut -d/ -f2`
elif [ -b $2 ]; then
  MD=`basename $2`
elif [ -b /dev/$2 ]; then
  MD="$2"
else
  echo "I dont know what to do with $2!"
  exit 3
fi

if ! grep "^${MD} : " /proc/mdstat; then
  echo "Did not find ${MD} in /proc/mdstat"
fi

case "$1" in
      none) mdadm -G --bitmap=none /dev/${MD} ;;
  internal) mdadm -G --bitmap=internal /dev/${MD} ;;
         *) usage;;
esac
