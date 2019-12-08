#!/bin/bash
if [ -z "$3" ];then
echo Usage: x3650m4 IP User Password
exit
fi

IP=$1
User=$2
PW=$3


mkdir -p log/${IP}

curl -c cckk.ck -o oob.log -s -k -X POST https://${IP}/data/login -d "user=$User&password=$PW&SessionTimeout=1200"
curl -b cckk.ck -o log/${IP}/x3650m4_${IP}_imm_info.json            -s -k https://${IP}/designs/imm/dataproviders/imm_info.php
curl -b cckk.ck -o log/${IP}/x3650m4_${IP}_imm_event_log.json       -s -k https://${IP}/designs/imm/dataproviders/imm_event_log.php
curl -b cckk.ck -o log/${IP}/x3650m4_${IP}_imm_hw_count.json        -s -k https://${IP}/designs/imm/dataproviders/imm_hw_count.php
curl -b cckk.ck -o log/${IP}/x3650m4_${IP}_imm_processors.json      -s -k https://${IP}/designs/imm/dataproviders/imm_processors.php
curl -b cckk.ck -o log/${IP}/x3650m4_${IP}_imm_memory.json          -s -k https://${IP}/designs/imm/dataproviders/imm_memory.php
curl -b cckk.ck -o log/${IP}/x3650m4_${IP}_imm_leds_all.json        -s -k https://${IP}/designs/imm/dataproviders/imm_leds_all.php
curl -b cckk.ck -o log/${IP}/x3650m4_${IP}_imm_power_supplies.json  -s -k https://${IP}/designs/imm/dataproviders/imm_power_supplies.php
curl -b cckk.ck -o log/${IP}/x3650m4_${IP}_imm_cooling.json         -s -k https://${IP}/designs/imm/dataproviders/imm_cooling.php
curl -b cckk.ck -o log/${IP}/x3650m4_${IP}_raid_arrayphysical.json  -s -k https://${IP}/designs/imm/dataproviders/raid_arrayphysical.php
curl -b cckk.ck -o log/${IP}/x3650m4_${IP}_raid_alldevices.json     -s -k https://${IP}/designs/imm/dataproviders/raid_alldevices.php
curl -b cckk.ck -o log/${IP}/x3650m4_${IP}_raid_arraylogic.json     -s -k https://${IP}/designs/imm/dataproviders/raid_arraylogic.php

curl -b cckk.ck -o log/${IP}/x3650m4_${IP}_imm_props_environ_vol.json       -s -k https://${IP}/designs/imm/dataproviders/imm_props_environ_vol.php
curl -b cckk.ck -o log/${IP}/x3650m4_${IP}_imm_props_environ_tmp.json       -s -k https://${IP}/designs/imm/dataproviders/imm_props_environ_tmp.php
curl -b cckk.ck -o log/${IP}/x3650m4_${IP}_imm_props_hardware_com.json      -s -k https://${IP}/designs/imm/dataproviders/imm_props_hardware_com.php
curl -b cckk.ck -o log/${IP}/x3650m4_${IP}_imm_props_hardware_net.json      -s -k https://${IP}/designs/imm/dataproviders/imm_props_hardware_net.php
curl -b cckk.ck -o log/${IP}/x3650m4_${IP}_imm_props_hardware_activity.json -s -k https://${IP}/designs/imm/dataproviders/imm_props_hardware_activity.php

curl -b cckk.ck -o oob.log -s -k https://${IP}/data/logout
rm -f cckk.ck
rm -f oob.log

