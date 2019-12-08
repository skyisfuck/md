#!/bin/bash
if [ -z "$3" ];then
echo Usage: nf5280 IP User Password
exit
fi

IP=$1
User=$2
PW=$3

curl -c cckk.ck -o oob.log -s -k https://${IP}/api/session -d "username=e-a-1a-d-6&password=15-11-1d-1e-11-14-5e-4d-4c&encrypt_flag=1"
if [ ! -f cckk.ck ];then
echo Login Server $IP error!
exit 1
fi
if [ ! -d log/${IP} ];then
mkdir -p log/${IP}
fi

cookie=`cat cckk.ck|grep QSESSIONID|awk '{print $7}'`
tk=`cat oob.log|awk -F '"' '{print $30}'`
curl -o log/${IP}/nf5280_${IP}_jviewer.jnlp -s -k https://${IP}/video/jviewer.jnlp -H "Cookie: QSESSIONID=$cookie; refresh_disable=1" -H "X-CSRFTOKEN: $tk"
/bin/javaws log/${IP}/nf5280_${IP}_jviewer.jnlp
curl -o oob.log -X DELETE       -s -k https://${IP}/api/session -H "Cookie: QSESSIONID=$cookie; refresh_disable=1" -H "X-CSRFTOKEN: $tk"
rm -f cckk.ck
rm -f oob.log
