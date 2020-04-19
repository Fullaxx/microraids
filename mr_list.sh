#!/bin/bash

set -e

if [ "$#" -ne "1" ]; then
  echo "$0: <MAP>"
  exit 1
fi

MAP="$1"

if [ `id -u` -ne "0" ]; then
  echo "Got Root?"
  exit 2
fi

if [ ! -r ${MAP} ]; then
  echo "${MAP} is not readable!"
  exit 3
fi

INDEX="0"
declare -a loc_array
while read -r LINE; do
  loc_array[${INDEX}]="${LINE}"
  INDEX=$(( INDEX+1 ))
done < ${MAP}

echo "${loc_array[@]}" | xargs -n1 ls -1 | sort -u
