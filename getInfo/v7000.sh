#! /bin/bash
# V7000 default User is aaaaaa password is aaaaaa
# Input  v7000_IP  v7000_User v7000_passwd
vUser=aaaaaa
vPW=aaaaaa
vIP=$1

# Get V7000 V5000 info
function getv7k(){
echo "------ System info ------"
sshpass -p $vPW ssh $vUser@$vIP lssystem -delim ':'                

echo "------ System IP ------"
sshpass -p $vPW ssh $vUser@$vIP lssystemip -delim ':'

sshpass -p $vPW ssh $vUser@$vIP lsenclosure -nohdr -delim ':' > node.dry
for i in $(cat node.dry);
do
nn=`echo $i|awk -F ':' '{print $1}'`

echo "------ Enclosure:$nn ------"
sshpass -p $vPW ssh $vUser@$vIP lsenclosure -delim ':' $nn

echo "------ Enclosure $nn Canister 1 ------"
sshpass -p $vPW ssh $vUser@$vIP lsenclosurecanister -delim ':' -canister 1 $nn
echo "------ Enclosure $nn Canister 2 ------"
sshpass -p $vPW ssh $vUser@$vIP lsenclosurecanister -delim ':' -canister 2 $nn

echo "------ Enclosure $nn Power Supply 1 ------"
sshpass -p $vPW ssh $vUser@$vIP lsenclosurepsu -delim ':' -psu 1 $nn
echo "------ Enclosure $nn Power Supply 2 ------"
sshpass -p $vPW ssh $vUser@$vIP lsenclosurepsu -delim ':' -psu 2 $nn

echo "------ Enclosure $nn Fan Module 1 ------"
sshpass -p $vPW ssh $vUser@$vIP lsenclosurefanmodule -delim ':' -fanmodule 1 $nn
echo "------ Enclosure $nn Fan Module 2 ------"
sshpass -p $vPW ssh $vUser@$vIP lsenclosurefanmodule -delim ':' -fanmodule 2 $nn

echo "------ Enclosure $nn Battery 1 ------"
sshpass -p $vPW ssh $vUser@$vIP lsenclosurebattery -delim ':' -battery 1 $nn 2>/dev/null
echo "------ Enclosure $nn Battery 2 ------"
sshpass -p $vPW ssh $vUser@$vIP lsenclosurebattery -delim ':' -battery 2 $nn 2>/dev/null

echo "------ Enclosure $nn Slot ------"
sshpass -p $vPW ssh $vUser@$vIP lsenclosureslot  -delim ':' $nn
done

echo "------ Drive ------"
sshpass -p $vPW ssh $vUser@$vIP lsdrive  -delim ':'  

# sshpass -p $vPW ssh $vUser@$vIP lsdrive  -nohdr -delim ':' > node.dry 
# for i in $(cat node.dry);
# do
# nn=`echo $i|awk -F ':' '{print $1}'`
# echo ------ Drive:$nn
# sshpass -p $vPW ssh $vUser@$vIP lsdrive -delim ':' $nn
# done 

echo "------ Mdisk ------"
sshpass -p $vPW ssh $vUser@$vIP lsmdisk  -delim ':'

echo "------ Mdisk group ------"
sshpass -p $vPW ssh $vUser@$vIP lsmdiskgrp  -delim ':'

echo "------ Array info ------"
sshpass -p $vPW ssh $vUser@$vIP lsarray  -delim ':' 

echo "------ Vdisk ------"
sshpass -p $vPW ssh $vUser@$vIP lsvdisk  -delim ':'     

echo "------ Host ------"
sshpass -p $vPW ssh $vUser@$vIP lshost  -delim ':'  
sshpass -p $vPW ssh $vUser@$vIP lshost  -nohdr -delim ':' > node.dry  
for i in $(cat node.dry);
do
nn=`echo $i|awk -F ':' '{print $1}'`

echo "------ Host:$nn ------"
sshpass -p $vPW ssh $vUser@$vIP lshost  -delim ':' $nn
done 

echo "------ Host vdisk map ------"
sshpass -p $vPW ssh $vUser@$vIP lshostvdiskmap  -delim ':'

echo "------ Event log ------"
sshpass -p $vPW ssh $vUser@$vIP lseventlog  -delim ':'

rm -f node.dry >/dev/null
}

if [ -z "$3" ];then
echo Usage: getv7000 V7000_IP V7000_user V7000_passwd
exit
fi
vIP=$1
vUser=$2
vPW=$3

mkdir -p log/${1}
getv7k > log/${1}/V7000_$vIP.txt
