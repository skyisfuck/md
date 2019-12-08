@echo off
rem dl580g7 <IP> <User> <Password>
if "%1"=="" (
echo Usage: dl580g7 IP User Password
goto end
)
if "%2"=="" (
echo Usage: dl580g7 IP User Password
goto end
)
if "%3"=="" (
echo Usage: dl580g7 IP User Password
goto end
)

set IP=%1
set User=%2
set PW=%3

rem set IP=30.107.0.84
rem set User=query
rem set PW=aaaaaa!23

echo {"method":"login","user_login":"%User%","password":"%PW%"} >login.json
curl -c cckk.ck -o oob.log -s -s -k https://%IP%/json/login_session -d @login.json
for /f "tokens=7 delims=	" %%a in ('findstr "sessionKey" cckk.ck') do set CK=%%a

curl -o dl580_%IP%_overview.json 		-s -k https://%IP%/json/overview 		-H "Cookie: sessionLang=en; sessionKey=%CK%"
curl -o dl580_%IP%_proc_info.json 		-s -k https://%IP%/json/proc_info 		-H "Cookie: sessionLang=en; sessionKey=%CK%"
curl -o dl580_%IP%_mem_info.json 		-s -k https://%IP%/json/mem_info 		-H "Cookie: sessionLang=en; sessionKey=%CK%"
curl -o dl580_%IP%_nic_info.json 		-s -k https://%IP%/json/nic_info 		-H "Cookie: sessionLang=en; sessionKey=%CK%"

rem curl -o dl580_%IP%_host_power.json 		-s -k https://%IP%/json/host_power		-H "Cookie: sessionLang=en; sessionKey=%CK%"
rem curl -o dl580_%IP%_drives_status.json 	-s -k https://%IP%/json/drives_status 	-H "Cookie: sessionLang=en; sessionKey=%CK%"
rem curl -o dl580_%IP%_health_summary.json 		-s -k https://%IP%/json/health_summary 		-H "Cookie: sessionLang=en; sessionKey=%CK%"
rem curl -o dl580_%IP%_health_fans.json 		-s -k https://%IP%/json/health_fans			-H "Cookie: sessionLang=en; sessionKey=%CK%"
rem curl -o dl580_%IP%_health_temperature.json 	-s -k https://%IP%/json/health_temperature 	-H "Cookie: sessionLang=en; sessionKey=%CK%"
rem curl -o dl580_%IP%_health_power_supply.json -s -k https://%IP%/json/health_power_supply	-H "Cookie: sessionLang=en; sessionKey=%CK%"
rem curl -o dl580_%IP%_health_vrm.json 			-s -k https://%IP%/json/health_vrm 			-H "Cookie: sessionLang=en; sessionKey=%CK%"

curl -o dl580_%IP%_power_capabilities.json 	-s -k https://%IP%/json/power_capabilities	-H "Cookie: sessionLang=en; sessionKey=%CK%"
curl -o dl580_%IP%_power_supplies.json 		-s -k https://%IP%/json/power_supplies 		-H "Cookie: sessionLang=en; sessionKey=%CK%"
curl -o dl580_%IP%_power_readings.json 		-s -k https://%IP%/json/power_readings 		-H "Cookie: sessionLang=en; sessionKey=%CK%"

HPQLOCFG -s %IP% -u %User% -p %PW% -l dl580_%IP%_sys_Log.xml -f sys_Log.xml  >nul 
HPQLOCFG -s %IP% -u %User% -p %PW% -l dl580_%IP%_iLO_log.xml -f iLO_Log.xml >nul

echo {"method":"logout","session_key":"%CK%"} >logout.json
curl -o oob.log -X POST -s -k https://%IP%/json/login_session -d @logout.json

del login.json
del logout.json
del cckk.ck
del oob.log
:end
