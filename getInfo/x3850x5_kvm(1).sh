#!/bin/bash
#JAVA 1.6 installed in /home/jntomcat/jre1.6.0_45

if [ -z "$3" ];then
echo Usage: x3850x5 IP User Password
exit
fi

IP=$1
User=$2
PW=$3


curl -o cckk.ck -s -k -X POST "http://${IP}/session/create" -d "$User,$PW"

if [ ! -f cckk.ck ];then
echo Login Server $IP error!
exit 1
fi
cookie=`cat cckk.ck |awk -F ':' '{print $2}'`
if [ ! -d log/${IP} ];then
mkdir -p log/${IP}
fi

#curl  -o log/${IP}/x3850x5_${IP}_vm.jnlp  -s -k  http://${IP}/kvm/vm/jnlp -H "session_id: $cookie"
#/home/jntomcat/jre1.6.0_45/bin/javaws log/${IP}/x3850x5_${IP}_vm.jnlp

curl  -o log/${IP}/x3850x5_${IP}_kvm.jnlp  -s -k  http://${IP}/kvm/kvm/jnlp -H "session_id: $cookie"
/home/jntomcat/jre1.6.0_45/bin/javaws log/${IP}/x3850x5_${IP}_kvm.jnlp

# Logout
curl -s -k -X POST "http://${IP}/session/deactivate" --data "" -H "session_id: $cookie"
rm -f cckk.ck

