@echo off
if "%1"=="" (
echo Usage: power-cfg HMC_IP Power_IP
goto end
)


ssh hscroot@%1 lssyscfg -r sys -F name,ipaddr,type_model >sys.txt
for /f "delims=, tokens=1,2*" %%r in (sys.txt) do ( 
if %2 == %%s (

if exist log\%%s ( echo ) else ( mkdir log\%%s )

call :getPowerinfo %1 %%r %%s > log\%%s\Power_%%s.txt
call :getASMinfo %1 %%s %%t > nul
goto end
)
)
echo Error: %1 or %2 
goto end


rem ========== Power info ==========Input (HMC IP,Power system name)
:getPowerinfo
echo ------ Power info ------
echo HMC IPaddr:%1
echo Power name:%2
echo Power IP  :%3

echo ------ Porcessor info ------
ssh hscroot@%1 lshwres  -r proc -F --header -m %2 --level sys 
echo ------ Memory info ------
ssh hscroot@%1 lshwres  -r mem  -F --header -m %2 --level sys 
echo ------ IO adapter info ------
rem ssh hscroot@%1 lsiotopo -F --header -m %1 
ssh hscroot@%1 lshwres -r io -F --header -m %2 --rsubtype slot 
echo ------ VIO adapter info------
ssh hscroot@%1 lshwres -r virtualio -m %2 --level slot --rsubtype slot
echo ------ HEA adapter info ------
ssh hscroot@%1 lshwres -r hea  -F --header -m %2 --rsubtype logical --level port 
echo ------ Partition profile info------
ssh hscroot@%1 lssyscfg -r prof -F --header -m %2 
echo ------ Partition info------
ssh hscroot@%1 lssyscfg -r lpar -F --header -m %2 
echo ------ Partition Processor info------
ssh hscroot@%1 lshwres  -r proc -F --header -m %2 --level lpar  
echo ------ Partition Memory info------
ssh hscroot@%1 lshwres  -r mem  -F --header -m %2 --level lpar 
echo ------ Power LED info------
ssh hscroot@%1 lsled -r sa -t phys -m %2
goto :eof

rem ========== ASM info ========== Input (HMC IP,Power system IP,Power system type)
:getASMinfo
for /f "delims=. tokens=1,2,3*" %%a in ("%1") do (set pp=%%a%%b%%c%%d )
for /f "delims=. tokens=1,2,3*" %%a in ("%2") do (set qq=%%a%%b%%c%%d )
set ss=%pp:~-3,2%
set tt=%qq:~-4,3%
set sshport=%ss%%tt%

start /b ssh -f -N -L %sshport%:%2:443 hscroot@%1
goto %3

:8202-E4C
:8202-E4B
:8205-E6B
:8233-E8B
curl -s -k -c cckk.ck -o hmc.log  -X POST            "https://127.0.0.1:%sshport%/cgi-bin/cgi" -d "user=admin&password=admin&lang=0&submit=Log+in"
curl -s -k -b cckk.ck -o log\%2\Power_%2_System.html        "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=4"
curl -s -k -b cckk.ck -o log\%2\Power_%2_Logs.html          "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=29"
curl -s -k -b cckk.ck -o log\%2\Power_%2_Memory.html        "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=35" 
curl -s -k -b cckk.ck -o log\%2\Power_%2_Processor.html     "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=37" 
curl -s -k -b cckk.ck -o log\%2\Power_%2_SystemLED.html     "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=46"
curl -s -k -b cckk.ck -o log\%2\Power_%2_EnclosureLED.html  "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=47" 
curl -s -k -b cckk.ck -o log\%2\Power_%2_VPDs.html  -X POST "https://127.0.0.1:%sshport%/cgi-bin/cgi" -d "form=3&showall=Display+all+details"
curl -s -k -b cckk.ck -o hmc.log             -X POST "https://127.0.0.1:%sshport%/cgi-bin/cgi" -d "submit=Log+out"
goto asmend

:8202-E4D
:8205-E6D
curl -s -k -c cckk.ck -o hmc.log -X POST             "https://127.0.0.1:%sshport%/cgi-bin/cgi" -d "user=admin&password=admin&lang=0&login=Log+in"
curl -s -k -b cckk.ck -o log\%2\Power_%2_System.html        "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=4"
curl -s -k -b cckk.ck -o log\%2\Power_%2_Logs.html          "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=30"
curl -s -k -b cckk.ck -o log\%2\Power_%2_Memory.html        "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=37" 
curl -s -k -b cckk.ck -o log\%2\Power_%2_Processor.html     "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=39" 
curl -s -k -b cckk.ck -o log\%2\Power_%2_SystemLED.html     "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=49"
curl -s -k -b cckk.ck -o log\%2\Power_%2_EnclosureLED.html  "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=50" 
curl -s -k -b cckk.ck -o log\%2\Power_%2_VPDs.html  -X POST "https://127.0.0.1:%sshport%/cgi-bin/cgi" -d "form=3&showall=Display+all+details"
curl -s -k -b cckk.ck -o hmc.log             -X POST "https://127.0.0.1:%sshport%/cgi-bin/cgi" -d "submit=Log+out"
goto asmend

:8203-E4A
:8204-E8A
:9119-FHA
curl -s -k -c cckk.ck -o hmc.log -X POST             "https://127.0.0.1:%sshport%/cgi-bin/cgi" -d "user=admin&password=admin&lang=0&login=Log+in"
curl -s -k -b cckk.ck -o log\%2\Power_%2_System.html        "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=4"
curl -s -k -b cckk.ck -o log\%2\Power_%2_Logs.html          "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=29"
curl -s -k -b cckk.ck -o log\%2\Power_%2_Memory.html        "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=35" 
curl -s -k -b cckk.ck -o log\%2\Power_%2_Processor.html     "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=37" 
curl -s -k -b cckk.ck -o log\%2\Power_%2_SystemLED.html     "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=52"
curl -s -k -b cckk.ck -o log\%2\Power_%2_EnclosureLED.html  "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=53" 
curl -s -k -b cckk.ck -o log\%2\Power_%2_VPDs.html  -X POST "https://127.0.0.1:%sshport%/cgi-bin/cgi" -d "form=3&showall=Display+all+details"
curl -s -k -b cckk.ck -o hmc.log             -X POST "https://127.0.0.1:%sshport%/cgi-bin/cgi" -d "submit=Log+out"
goto asmend

:8284-22A
curl -s -k -c cckk.ck -o hmc.log -X POST            "https://127.0.0.1:%sshport%/cgi-bin/cgi" -d "CSRF_TOKEN=0&user=admin&password=admin&lang=0&login=Log+in"
curl -s -k -b cckk.ck -o log\%2\Power_%2_System.html       "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=4"
curl -s -k -b cckk.ck -o log\%2\Power_%2_Logs.html         "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=31"
curl -s -k -b cckk.ck -o log\%2\Power_%2_Memory.html       "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=37" 
curl -s -k -b cckk.ck -o log\%2\Power_%2_Processor.html    "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=39" 
curl -s -k -b cckk.ck -o log\%2\Power_%2_SystemLED.html    "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=49"
curl -s -k -b cckk.ck -o log\%2\Power_%2_EnclosureLED.html "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=50" 
curl -s -k -b cckk.ck -o log\%2\Power_%2_VPDs.html -X POST "https://127.0.0.1:%sshport%/cgi-bin/cgi" -d "form=3&CSRF_TOKEN=0&showall=Display+all+details"
curl -s -k -b cckk.ck -o hmc.log -X POST            "https://127.0.0.1:%sshport%/cgi-bin/cgi" -d "CSRF_TOKEN=0&submit=Log+out"
goto asmend

:9131-52A
goto :eof
curl -s -k -c cckk.ck -o hmc.log -X POST             "https://127.0.0.1:%sshport%/cgi-bin/cgi" -d "user=admin&password=admin&lang=0&login=Log+in"
curl -s -k -b cckk.ck -o log\%2\Power_%2_System.html        "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=4"
curl -s -k -b cckk.ck -o log\%2\Power_%2_Logs.html          "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=28"
curl -s -k -b cckk.ck -o log\%2\Power_%2_Memory.html        "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=34" 
curl -s -k -b cckk.ck -o log\%2\Power_%2_Processor.html     "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=36" 
curl -s -k -b cckk.ck -o log\%2\Power_%2_SystemLED.html     "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=51"
curl -s -k -b cckk.ck -o log\%2\Power_%2_EnclosureLED.html  "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=52" 
curl -s -k -b cckk.ck -o log\%2\Power_%2_VPDs.html  -X POST "https://127.0.0.1:%sshport%/cgi-bin/cgi" -d "form=3&showall=Display+all+details"
curl -s -k -b cckk.ck -o hmc.log             -X POST "https://127.0.0.1:%sshport%/cgi-bin/cgi" -d "submit=Log+out"
goto asmend

:9133-55A
goto :eof
curl -s -k -c cckk.ck -o hmc.log -X POST             "https://127.0.0.1:%sshport%/cgi-bin/cgi" -d "user=general&password=general&lang=0&login=Log+in"
curl -s -k -b cckk.ck -o log\%2\Power_%2_System.html        "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=4"
curl -s -k -b cckk.ck -o log\%2\Power_%2_Logs.html          "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=28"
rem curl -s -k -b cckk.ck -o log\%2\Power_%2_Memory.html       "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=34" 
rem curl -s -k -b cckk.ck -o log\%2\Power_%2_Processor.html    "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=36" 
rem curl -s -k -b cckk.ck -o log\%2\Power_%2_SystemLED.html    "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=51"
rem curl -s -k -b cckk.ck -o log\%2\Power_%2_EnclosureLED.html "https://127.0.0.1:%sshport%/cgi-bin/cgi?form=52" 
curl -s -k -b cckk.ck -o log\%2\Power_%2_VPDs.html -X POST  "https://127.0.0.1:%sshport%/cgi-bin/cgi" -d "form=3&showall=Display+all+details"
curl -s -k -b cckk.ck -o hmc.log -X POST             "https://127.0.0.1:%sshport%/cgi-bin/cgi" -d "submit=Log+out"

:asmend
del cckk.ck
del hmc.log
goto :eof

:end
del sys.txt 2>nul

