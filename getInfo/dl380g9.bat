@echo off
rem dl380g9 <IP> <User> <Password>
if "%1"=="" (
echo Usage: dl380g9 IP User Password
goto end
)
if "%2"=="" (
echo Usage: dl380g9 IP User Password
goto end
)
if "%3"=="" (
echo Usage: dl380g9 IP User Password
goto end
)

set IP=%1
set User=%2
set PW=%3

rem IP=30.107.0.2
rem User=````
rem PW=····

echo {"method":"login","user_login":"%User%","password":"%PW%"} >login.json

rem curl -c cckk.ck -o oob.log -s -k https://%IP%/json/login_session -H "Cookie: sessionUrl="; sessionLang=zh" -d @login.json
curl -c cckk.ck -o oob.log -s -k https://%IP%/json/login_session -d @login.json

for /f "tokens=7 delims=	" %%a in ('findstr "sessionKey" cckk.ck') do set CK=%%a
curl -o dl380_%IP%_overview.json 		-s -k https://%IP%/json/overview 	-H "Cookie: sessionLang=zh; sessionKey=%CK%"
curl -o dl380_%IP%_health_summary.json 	-s -k https://%IP%/json/health_summary 		-H "Cookie: sessionLang=zh; sessionKey=%CK%"
curl -o dl380_%IP%_pci_info.json 		-s -k https://%IP%/json/pci_info 		-H "Cookie: sessionLang=zh; sessionKey=%CK%"

HPQLOCFG -s %IP% -u %User% -p %PW% -l dl380_%IP%_sys_Log.xml -f dl380g9.xml >nul  
HPQLOCFG -s %IP% -u %User% -p %PW% -l dl380_%IP%_iLO_log.xml -f iLO_Log.xml >nul

echo {"method":"logout","session_key":"%CK%"} >logout.json
curl -o oob.log -X POST -s -k https://%IP%/json/login_session -d @logout.json

del login.json
del logout.json
del cckk.ck
del oob.log
:end
