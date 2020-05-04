#!/bin/bash

# default to creating btrfs filesystems
# unless you are on CentOS/RedHat where you want to set FSTYPE="ext4" or FSTYPE="xfs"
FSTYPE=${FSTYPE:-btrfs}

# Determine specific mkfs command, force flag, and max label length
case "${FSTYPE}" in
  btrfs) MLL="256"; FF="-f"; FSOPTS="" ;;
   ext4) MLL="16"; FF="-F"; FSOPTS="-O metadata_csum,64bit" ;;
    xfs) MLL="12"; FF="-f"; FSOPTS="" ;;
      *) echo "No suitable filesystem utility selected!"; exit 1 ;;
esac

MKFSCMD=`PATH="/sbin:/usr/sbin:$PATH" which mkfs.${FSTYPE}`
if [ "$?" != "0" ]; then
  echo "mkfs.${FSTYPE} not found!"
  exit 1
fi

if [ ${FSTYPE} != "btrfs" ]; then
  echo "The use of btrfs during disk preperation is highly recommended!"
  echo "btrfs supports FS labels upto 256 characters and allows for data scrubbing"
  echo "ext4 and xfs require labels between 12-16 characters and do not checksum data blocks"
  echo -n "Are you sure you want to continue? (y/N)? "
  read ANS
  if [ "${ANS}" != "y" ] && [ "${ANS}" != "Y" ]; then exit 0; fi
fi

# If dialog not installed, bail out
if [ -z "`which dialog`" ]; then
  echo "Package 'dialog' not found, please install it before continuing."
  exit 1
fi

# Define the dialog exit status codes
: ${DIALOG_OK=0}
: ${DIALOG_CANCEL=1}
: ${DIALOG_HELP=2}
: ${DIALOG_EXTRA=3}
: ${DIALOG_ITEM_HELP=4}
: ${DIALOG_ESC=255}

# Search for disks with no partitions
MRDEVICES=""
for DISK in `lsblk | awk '$6=="disk" {print $1}'`; do
# echo ${DISK}
  if ! lsblk | awk '$6=="part" {print $1}' | grep -q ${DISK}; then
    MRDEVICES+="/dev/${DISK} "
  fi
done

# Build our DEVICE_ARRAY so that each disk has a corresponding index value
# That index value will be referenced during disk selection
INDEX="0"
CHECKLISTSTRING=""
declare -a DEVICE_ARRAY
for device in ${MRDEVICES}; do
  DEVICE_ARRAY[${INDEX}]="${device}"
  CHECKLISTSTRING+="${INDEX} ${device} off "
  INDEX=$((INDEX + 1))
done

#echo "INDEX: ${INDEX}"
#echo "CHECKLISTSTRING: ${CHECKLISTSTRING}"

# If we didn't find any suitable devices to populate our dialog menu, bail out.
if [ "${INDEX}" -eq 0 ]; then
  dialog --backtitle "Microraid Setup" \
         --title "Microraid Physical Disk Selection Error" \
         --msgbox "No blank (unmounted) disks available.  Bailing!" 8 50
  echo -e "Couldn't determine valid base disk set.\nAttach unpartitioned disks to this machine and try again."
  exit 1
fi

# We have at least 1 valid device to use for microraids
# Present them to the user to select for partitioning
exec 3>&1
SELECTION=$(dialog --backtitle "Microraid Setup" --title "Microraid Physical Disk Selection" --checklist "You must select all disks to use for a new microraid base.  ALL DATA ON THESE DISKS WILL BE LOST!" 18 60 ${INDEX} ${CHECKLISTSTRING} 2>&1 1>&3)
dialog_return_code=$?
exec 3>&-

# Check exit status of dialog to see if user cancelled, bail if so
if [ "$dialog_return_code" != "0" ]; then
  dialog --backtitle "Microraid Setup" \
         --title "Microraid Physical Disk Selection Error" \
         --msgbox "Cancelled! No disks were modified." 8 50
  echo "User cancelled or other error occurred."
  exit 1
fi

#echo "SELECTION: $SELECTION"
#echo "DEVICE ARRAY WAS ${DEVICE_ARRAY[@]}"

# Generate the list of devices based on user selection
DEVICES=""
for choice in ${SELECTION}; do
  DEVICES+="${DEVICE_ARRAY[choice]} "
done

if [ -z "${DEVICES}" ]; then
  dialog --backtitle "Microraid Setup" \
         --title "Microraid Physical Disk Selection Error" \
         --msgbox "No disks were selected!" 8 50
  echo "No disks were selected!"
  exit 1
fi

# Give one last chance to cancel out...
dialog --backtitle "Microraid Setup" \
       --title "Microraid Physical Disk Selection Confirmation" \
       --yesno "Disk(s) ${DEVICES} will be formatted now and used as a base for the microraid. Are you sure you want to continue?" 8 50
dialog_return_code=$?
if [ "$dialog_return_code" != "0" ]; then
  dialog --backtitle "Microraid Setup" \
         --title "Microraid Physical Disk Selection Error" \
         --msgbox "Cancelled! No disks were modified." 8 50
  echo "User cancelled or other error occurred."
  exit 1
fi

set -e

# User has given permission ...
# Create the partitions and filesystems
MOUNTMAP="mnt_locations.map"
for DISK in ${DEVICES}; do
  sgdisk -Z ${DISK}
  sgdisk -n 1:0:0 ${DISK}
  sgdisk -t 1:8300 ${DISK}
  PART="${DISK}1"
  LABEL=$(hdparm -I ${DISK} | grep 'Serial Number:' | awk '{print $3}' | cut -c -${MLL})
  ${MKFSCMD} ${FF} ${FSOPTS} -L ${LABEL} ${PART}
  mkdir -p /mnt/${LABEL}
  mount ${PART} /mnt/${LABEL}
  echo "/mnt/${LABEL}" >> ${MOUNTMAP}
done

echo "Done! microraid mount locations at ${MOUNTMAP}"
exit 0
