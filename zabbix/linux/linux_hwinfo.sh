#!/bin/bash
###################################
# Description: get system hardware info
# Author: ningpeng
# Version: 1.0
# Last Update: 2019.4.2
# system: CentOS 6,7
###################################

echo  "----------------------------------------system info----------------------------------------"
# system info
dmidecode |grep -A16 "System Information$"

# cpu info
echo  "------------------------------------------cpu info------------------------------------------"
lscpu

# mem info
echo  "------------------------------------------mem info------------------------------------------"
free -h | awk '/Mem/{printf "Total Mem: %20s\n",$2}'
dmidecode -t 17 | egrep "Size|Locator|Speed|Manufacturer|Memory Device" | grep -v "Bank"

# netcard info
echo  "----------------------------------------netcard info----------------------------------------"
dmesg | grep "Ethernet"

# disk info
echo  "-----------------------------------------disk info------------------------------------------"
lsscsi
lsblk | grep "^sd" | awk '{printf "/dev/%s: %20s\n",$1,$4}'
