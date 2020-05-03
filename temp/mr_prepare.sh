#!/bin/bash

#DEVICES="`find /dev -type b`"
DEVICES="`find dev -type f`"

CHECKLISTSTRING=""
devicecounter="0"

#loop through all devices, check if they have a partition mounted or not and add it to the 
#list if it looks like this is a blank (unpartitioned, unmounted) device.
for device in $DEVICES; do
	#populate a list of devices that don't have something mounted from them, i.e. they are blank
	#if [ -z "`mount | grep $device`" ]; then 
	if [ -z "`cat mount.txt | grep $device`" ]; then
		CHECKLISTSTRING+="$devicecounter \"$device\" off "
		devicecounter=$((devicecounter + 1))
	fi
done

echo "devicecounter was $devicecounter"
echo "CHECKLISTSTRING was $CHECKLISTSTRING"

#If we didn't find any suitable devices to populate our dialog menu, bail out.
if [ "$devicecounter" -eq 0 ]; then
	dialog --backtitle "Microraid Setup" --title "Microraid Physical Disk Selection Error" --msgbox "No blank (unmounted) disks available.  Bailing!" 8 50
	echo "Couldn't determine valid base disk set. Attach unpartitioned disks to this machine and try again."
	exit 1
fi


dialog --backtitle "Microraid Setup" --title "Microraid Physical Disk Selection" --checklist "You must select all disks to use for a new microraid base.  ALL DATA ON THESE DISKS WILL BE LOST!" 18 60 $devicecounter $CHECKLISTSTRING

