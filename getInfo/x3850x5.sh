#!/bin/bash
if [ -z "$3" ];then
echo Usage: x3850x5 IP User Password
exit
fi

IP=$1
User=$2
PW=$3


mkdir -p log/${IP}

curl -o cckk.ck -s -k -X POST "http://${IP}/session/create" -d "$User,$PW"
cookie=`cat cckk.ck |awk -F ':' '{print $2}'`

# System Status
curl -d "@x3850status1.txt" -o log/${IP}/x3850x5_${IP}_status1.xml -s -k -X POST http://${IP}/wsman -H "session_id: $cookie"
curl -d "@x3850status2.txt" -o log/${IP}/x3850x5_${IP}_status2.xml -s -k -X POST http://${IP}/wsman -H "session_id: $cookie"
curl -d "@x3850status3.txt" -o log/${IP}/x3850x5_${IP}_status3.xml -s -k -X POST http://${IP}/wsman -H "session_id: $cookie"

# Virtual Light Path
curl -d "@x3850light.txt" -o log/${IP}/x3850x5_${IP}_light.xml -s -k -X POST http://${IP}/wsman -H "session_id: $cookie"

# Event Log
curl -d "@x3850elog.txt" -o log/${IP}/x3850x5_${IP}_elog.xml -s -k -X POST http://${IP}/wsman -H "session_id: $cookie"

# Vital Product Data
curl -d "@x3850vpdata1.txt" -o log/${IP}/x3850x5_${IP}_vpdata1.xml -s -k -X POST http://${IP}/wsman -H "session_id: $cookie"
curl -d "@x3850vpdata2.txt" -o log/${IP}/x3850x5_${IP}_vpdata2.xml -s -k -X POST http://${IP}/wsman -H "session_id: $cookie"
curl -d "@x3850vpdata3.txt" -o log/${IP}/x3850x5_${IP}_vpdata3.xml -s -k -X POST http://${IP}/wsman -H "session_id: $cookie"
curl -d "@x3850vpdata4.txt" -o log/${IP}/x3850x5_${IP}_vpdata4.xml -s -k -X POST http://${IP}/wsman -H "session_id: $cookie"

# Logout
curl -s -k -X POST "http://${IP}/session/deactivate" --data "" -H "session_id: $cookie"
rm -f cckk.ck

