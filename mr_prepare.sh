#!/bin/bash

#dialog --backtitle "Microraid Setup" --title "Microraid Physical Disk Selection" --msgbox "You must select all disks to use for a new microraid base." 6 60
dialog --backtitle "Microraid Setup" --title "Microraid Physical Disk Selection" --checklist "You must select all disks to use for a new microraid base." 18 60 3 1 "test1" off 2 "test2" off 3 "test3" off
