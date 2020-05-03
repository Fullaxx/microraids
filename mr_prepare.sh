#!/bin/bash

# Define the dialog exit status codes
: ${DIALOG_OK=0}
: ${DIALOG_CANCEL=1}
: ${DIALOG_HELP=2}
: ${DIALOG_EXTRA=3}
: ${DIALOG_ITEM_HELP=4}
: ${DIALOG_ESC=255}

#Grab a list of all disks and partitions on the system
DISKS="`lsblk | awk '{print $1,$6}' | grep disk | awk '{print $1}' | tr '\n' ' '`"
PARTS="`lsblk | grep part | awk '{print $1}' | tr '└─' '\0'| tr '\n' ' '`"

#generate a list of devices that are disks with partitions that we assume are not blank and can not be used for the microraid
DEVICES=""
#echo "DISKS was $DISKS"
#echo "PARTS was $PARTS"
for disk in $DISKS; do
	for part in $PARTS; do
		if [[ "$part" =~ "$disk" ]]; then
			#echo "compared disk $disk to part $part"
			DEVICES+="$disk "
		fi
	done
done

#echo "USED DEVICES was $DEVICES"

#Now we need to compare our list of devices containing partitions to our list of disks, eliminate duplicates and what's leftover are usable blank disks
DEVICES+="$DISKS"
#echo "ALL DEVICES was $DEVICES"
BLANKDEVICES="`echo $DEVICES | tr ' ' '\n' | sort | uniq -u | tr '\n' ' '`"
#echo "BLANK DEVICES was $BLANKDEVICES"

#prepend the /dev/ prefix to each entry and rebuild DEVICES 
DEVICES=""
for device in $BLANKDEVICES; do
	DEVICES+="/dev/$device "
done
#echo "checking $DEVICES"

MOUNTMAP="mnt_locations.map"
CHECKLISTSTRING=""
devicecounter="0"
declare -a DEVICE_ARRAY

#if dialog not installed, bail out
if [ -z "`which dialog`" ]; then
	echo "Package 'dialog' not found, please install it before continuing."
	exit 1
fi

#build our DEVICE_ARRAY so that we know if a user chooses disk 1, it means the actual /dev/whatever device
for device in $DEVICES; do
	DEVICE_ARRAY[$devicecounter]="$device"
	CHECKLISTSTRING+="$devicecounter \"$device\" off "
	devicecounter=$((devicecounter + 1))
done

echo "devicecounter was $devicecounter"
echo "CHECKLISTSTRING was $CHECKLISTSTRING"

#If we didn't find any suitable devices to populate our dialog menu, bail out.
if [ "$devicecounter" -eq 0 ]; then
	dialog --backtitle "Microraid Setup" --title "Microraid Physical Disk Selection Error" --msgbox "No blank (unmounted) disks available.  Bailing!" 8 50
	echo "Couldn't determine valid base disk set. Attach unpartitioned disks to this machine and try again."
	exit 1
fi

#we have at least 1 valid device to use for microraids, let's present them to the user to select to include in the microraid base
exec 3>&1
SELECTION=$(dialog --backtitle "Microraid Setup" --title "Microraid Physical Disk Selection" --checklist "You must select all disks to use for a new microraid base.  ALL DATA ON THESE DISKS WILL BE LOST!" 18 60 $devicecounter $CHECKLISTSTRING 2>&1 1>&3)
dialog_return_code=$?
exec 3>&-

#Check exit status of dialog to see if user cancelled, bail if so
if ! [ "$dialog_return_code" -eq "0" ]; then
	dialog --backtitle "Microraid Setup" --title "Microraid Physical Disk Selection Error" --msgbox "Cancelled! No disks were modified." 8 50
	echo "User cancelled or other error occurred."
	exit 1
fi

#echo "SELECTION WAS: $SELECTION"
#echo "DEVICE ARRAY WAS ${DEVICE_ARRAY[@]}"

#generate the list of devices based on the selection we made
DEVICES=""
for choice in $SELECTION; do
	DEVICES+="${DEVICE_ARRAY[choice]} "
done

#give one last chance to cancel out...
dialog --backtitle "Microraid Setup" --title "Microraid Physical Disk Selection Confirmation" --yesno "Disk(s) $DEVICES will be formatted now and used as a base for the microraid. Are you sure you want to continue?" 8 50
dialog_return_code=$?
if ! [ "$dialog_return_code" -eq "0" ]; then
        dialog --backtitle "Microraid Setup" --title "Microraid Physical Disk Selection Error" --msgbox "Cancelled! No disks were modified." 8 50
        echo "User cancelled or other error occurred."
        exit 1
fi


#user has verified to wipe the disks and make the microraid... proceed
for DISK in $DEVICES; do
	sgdisk -n 1:0:0 ${DISK}
	sgdisk -t 1:8300 ${DISK}
done

#now create filesystems...
for DISK in $DEVICES; do
	PART="${DISK}1"
 	LABEL=$(hdparm -I ${DISK} | grep 'Serial Number:' | awk '{print $3}')
	mkfs.btrfs -f -L ${LABEL} ${PART}
	mkdir -p /mnt/${LABEL}
	mount ${PART} /mnt/${LABEL} -t btrfs
	echo "/mnt/${LABEL}" >> $MOUNTMAP
done

echo "Done! microraid mount locations at $MOUNTMAP"
exit 0
