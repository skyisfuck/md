@echo off
rem oob-ii <ip> <user> <passord>
rem oob-ii 10.250.0.7 admin admin

echo ----------  LAN  > %1.txt
oob\ipmiutil lan -c -N %1 -U %2 -P %3 >> %1.txt

echo ----------  LEDs  > %1.txt
oob\ipmiutil leds -r -x -N %1 -U %2 -P %3 >> %1.txt

echo ----------  Fru >> %1.txt
oob\ipmiutil fru -c -N %1 -U %2 -P %3 >> %1.txt

echo ----------  Sensor >> %1.txt
oob\ipmiutil sensor -c -e -v -N %1 -U %2 -P %3 >> %1.txt

echo ----------  Health >> %1.txt
oob\ipmiutil health -g -l -N %1 -U %2 -P %3 >> %1.txt

echo ----------  BMClog >> %1.txt
oob\ipmiutil sel -c -N %1 -U %2 -P %3 >> %1.txt



