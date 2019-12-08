#! /bin/bash
# V7000 default User is aaaaaa password is aaaaaa
# Input  v7000_IP  v7000_User v7000_passwd
vUser=aaaaaa
vPW=aaaaaa
vIP=$1

# Get V7000 V5000 info
function getv7k(){
sshpass -p $vPW ssh $vUser@$vIP lsenclosure -nohdr -delim ':' > node.dry
for i in $(cat node.dry);
do
nn=`echo $i|awk -F ':' '{print $1}'`
echo "------ Enclosure:$nn ------"
sshpass -p $vPW ssh $vUser@$vIP lsenclosure -delim ':' $nn
done
echo "------ Event log ------"
sshpass -p $vPW ssh $vUser@$vIP lseventlog  -delim ':'
rm -f node.dry >/dev/null
}

if [ $# -lt 3 ];then
echo Usage: getv7000 V7000_IP V7000_user V7000_passwd
exit
fi

vIP=$1
vUser=$2
vPW=$3

mkdir -p log/${1}
getv7k > log/${1}/V7000log_$vIP.txt
