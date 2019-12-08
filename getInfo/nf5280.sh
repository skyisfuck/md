#!/bin/bash
if [ -z "$3" ];then
echo Usage: nf5280 IP User Password
exit
fi

P=$1
User=$2
PW=$3

mkdir -p log/${IP}

curl -c cckk.ck -o oob.log -s -k https://${IP}/api/session -d "username=e-a-1a-d-6&password=15-11-1d-1e-11-14-5e-4d-4c&encrypt_flag=1"
cookie=`cat cckk.ck|grep QSESSIONID|awk '{print $7}'`
tk=`cat oob.log|awk -F '"' '{print $30}'`

curl -o log/${IP}/nf5280_${IP}_SATA_HDDinfo.json     -s -k https://${IP}/api/status/SATA_HDDinfo     -H "Cookie: QSESSIONID=$cookie; refresh_disable=1" -H "X-CSRFTOKEN: $tk"
curl -o log/${IP}/nf5280_${IP}_getctrlpdinfo.json -X POST -s -k https://${IP}/api/raid/getctrlpdinfo -H "Cookie: QSESSIONID=$cookie; refresh_disable=1" -H "X-CSRFTOKEN: $tk" -d "{""ctrlIndex"":0}"
curl -o log/${IP}/nf5280_${IP}_getctrlldinfo.json -X POST -s -k https://${IP}/api/raid/getctrlldinfo -H "Cookie: QSESSIONID=$cookie; refresh_disable=1" -H "X-CSRFTOKEN: $tk" -d "{""ctrlIndex"":0}"

curl -o log/${IP}/nf5280_${IP}_sensors.json               -s -k https://${IP}/api/sensors                   -H "Cookie: QSESSIONID=$cookie; refresh_disable=1" -H "X-CSRFTOKEN: $tk"
curl -o log/${IP}/nf5280_${IP}_event.json                 -s -k https://${IP}/api/logs/event                -H "Cookie: QSESSIONID=$cookie; refresh_disable=1" -H "X-CSRFTOKEN: $tk"
curl -o log/${IP}/nf5280_${IP}_fru.json                   -s -k https://${IP}/api/fru                       -H "Cookie: QSESSIONID=$cookie; refresh_disable=1" -H "X-CSRFTOKEN: $tk"
curl -o log/${IP}/nf5280_${IP}_harddisk_info.json         -s -k https://${IP}/api/status/harddisk_info      -H "Cookie: QSESSIONID=$cookie; refresh_disable=1" -H "X-CSRFTOKEN: $tk"
curl -o log/${IP}/nf5280_${IP}_SATA_HDDinfo.json          -s -k https://${IP}/api/status/SATA_HDDinfo       -H "Cookie: QSESSIONID=$cookie; refresh_disable=1" -H "X-CSRFTOKEN: $tk"
curl -o log/${IP}/nf5280_${IP}_chassis-status.json        -s -k https://${IP}/api/chassis-status            -H "Cookie: QSESSIONID=$cookie; refresh_disable=1" -H "X-CSRFTOKEN: $tk"
curl -o log/${IP}/nf5280_${IP}_diskbackplane_info.json    -s -k https://${IP}/api/status/diskbackplane_info -H "Cookie: QSESSIONID=$cookie; refresh_disable=1" -H "X-CSRFTOKEN: $tk"
curl -o log/${IP}/nf5280_${IP}_enclosure_info.json        -s -k https://${IP}/api/status/enclosure_info     -H "Cookie: QSESSIONID=$cookie; refresh_disable=1" -H "X-CSRFTOKEN: $tk"
curl -o log/${IP}/nf5280_${IP}_cpu_info.json              -s -k https://${IP}/api/status/cpu_info           -H "Cookie: QSESSIONID=$cookie; refresh_disable=1" -H "X-CSRFTOKEN: $tk"
curl -o log/${IP}/nf5280_${IP}_device_inventory.json      -s -k https://${IP}/api/status/device_inventory   -H "Cookie: QSESSIONID=$cookie; refresh_disable=1" -H "X-CSRFTOKEN: $tk"
curl -o log/${IP}/nf5280_${IP}_fan_info.json              -s -k https://${IP}/api/status/fan_info           -H "Cookie: QSESSIONID=$cookie; refresh_disable=1" -H "X-CSRFTOKEN: $tk"
curl -o log/${IP}/nf5280_${IP}_memory_info.json           -s -k https://${IP}/api/status/memory_info        -H "Cookie: QSESSIONID=$cookie; refresh_disable=1" -H "X-CSRFTOKEN: $tk"
curl -o log/${IP}/nf5280_${IP}_psu_info.json              -s -k https://${IP}/api/status/psu_info           -H "Cookie: QSESSIONID=$cookie; refresh_disable=1" -H "X-CSRFTOKEN: $tk"
curl -o log/${IP}/nf5280_${IP}_software_info.json         -s -k https://${IP}/api/status/software_info      -H "Cookie: QSESSIONID=$cookie; refresh_disable=1" -H "X-CSRFTOKEN: $tk"
curl -o log/${IP}/nf5280_${IP}_adapter_info.json          -s -k https://${IP}/api/status/adapter_info       -H "Cookie: QSESSIONID=$cookie; refresh_disable=1" -H "X-CSRFTOKEN: $tk"
curl -o log/${IP}/nf5280_${IP}_storage_info.json          -s -k https://${IP}/api/status/storage_info       -H "Cookie: QSESSIONID=$cookie; refresh_disable=1" -H "X-CSRFTOKEN: $tk"
curl -o log/${IP}/nf5280_${IP}_ctrlinfo.json              -s -k https://${IP}/api/raid/ctrlinfo             -H "Cookie: QSESSIONID=$cookie; refresh_disable=1" -H "X-CSRFTOKEN: $tk"
curl -o log/${IP}/nf5280_${IP}_ctrlprop.json              -s -k https://${IP}/api/raid/ctrlprop             -H "Cookie: QSESSIONID=$cookie; refresh_disable=1" -H "X-CSRFTOKEN: $tk"
curl -o log/${IP}/nf5280_${IP}_ctrlmfc.json               -s -k https://${IP}/api/raid/ctrlmfc              -H "Cookie: QSESSIONID=$cookie; refresh_disable=1" -H "X-CSRFTOKEN: $tk"
curl -o log/${IP}/nf5280_${IP}_getctrlcount.json          -s -k https://${IP}/api/raid/getctrlcount         -H "Cookie: QSESSIONID=$cookie; refresh_disable=1" -H "X-CSRFTOKEN: $tk"

curl -o oob.log -X DELETE       -s -k https://${IP}/api/session -H "Cookie: QSESSIONID=$cookie; refresh_disable=1" -H "X-CSRFTOKEN: $tk"
rm -f cckk.ck
rm -f oob.log
