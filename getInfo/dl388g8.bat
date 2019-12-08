@echo off
rem dl388g8 <IP> <User> <Password>
if "%3"=="" (
echo Usage: dl388g8 IP User Password
goto end
)

set IP=%1
set User=%2
set PW=%3

rem set IP=30.107.0.44
rem set User=query
rem set PW=aaaaaa!23

echo {"method":"login","user_login":"%User%","password":"%PW%"} >login.json
curl -c cckk.ck -o oob.log -s -s -k https://%IP%/json/login_session -d @login.json
for /f "tokens=7 delims=	" %%a in ('findstr "sessionKey" cckk.ck') do set CK=%%a

curl -o dl388_%IP%_overview.json 		-s -k https://%IP%/json/overview 		-H "Cookie: sessionLang=en; sessionKey=%CK%"
curl -o dl388_%IP%_proc_info.json 		-s -k https://%IP%/json/proc_info 		-H "Cookie: sessionLang=en; sessionKey=%CK%"
curl -o dl388_%IP%_mem_info.json 		-s -k https://%IP%/json/mem_info 		-H "Cookie: sessionLang=en; sessionKey=%CK%"
curl -o dl388_%IP%_nic_info.json 		-s -k https://%IP%/json/nic_info 		-H "Cookie: sessionLang=en; sessionKey=%CK%"
curl -o dl388_%IP%_health_drives.json 	-s -k https://%IP%/json/health_drives 	-H "Cookie: sessionLang=zh; sessionKey=%CK%"

curl -o dl388_%IP%_power_capabilities.json 	-s -k https://%IP%/json/power_capabilities	-H "Cookie: sessionLang=en; sessionKey=%CK%"
curl -o dl388_%IP%_power_supplies.json 		-s -k https://%IP%/json/power_supplies 		-H "Cookie: sessionLang=en; sessionKey=%CK%"
curl -o dl388_%IP%_power_readings.json 		-s -k https://%IP%/json/power_readings 		-H "Cookie: sessionLang=en; sessionKey=%CK%"

HPQLOCFG -s %IP% -u %User% -p %PW% -l dl388_%IP%_sys_Log.xml -f sys_Log.xml >nul  
HPQLOCFG -s %IP% -u %User% -p %PW% -l dl388_%IP%_iLO_log.xml -f iLO_Log.xml >nul

echo {"method":"logout","session_key":"%CK%"} >logout.json
curl -o oob.log -X POST -s -k https://%IP%/json/login_session -d @logout.json

del login.json
del logout.json
del cckk.ck
del oob.log
:end
