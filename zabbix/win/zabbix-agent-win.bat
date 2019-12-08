@echo off
color fd
cd \
#IP from Zabbix Server or proxy where data should be send to.
Set zabbix_server_ip=IP
echo Creating zabbix install dir
mkdir c:\zabbix
mkdir c:\zabbix\conf
mkdir c:\zabbix\bin
mkdir c:\zabbix\log
mkdir c:\zabbix\install_file
echo Copying Zabbix install file
xcopy \\共享服务器IP\Share\zabbix_agents_2.2.1.win c:\zabbix\install_file /s
copy /y C:\zabbix\install_file\conf\zabbix_agentd.win.conf C:\zabbix\conf\
echo Modiy zabbix configuration files
echo LogFile=c:\zabbix\log\zabbix_agentd.log >> C:\zabbix\conf\zabbix_agentd.win.conf
echo Server=%zabbix_server_ip% >> C:\zabbix\conf\zabbix_agentd.win.conf
echo Hostname=%COMPUTERNAME% >> C:\zabbix\conf\zabbix_agentd.win.conf
echo StartAgents=10 >> C:\zabbix\conf\zabbix_agentd.win.conf
echo Timeout=30 >> C:\zabbix\conf\zabbix_agentd.win.conf
echo
echo Copy zabbix start-up file
if %processor_architecture% EQU x86 copy /y C:\zabbix\install_file\bin\win32 C:\zabbix\bin\
if %processor_architecture% EQU AMD64 copy /y C:\zabbix\install_file\bin\win64 C:\zabbix\bin\
echo start zabbix servic
C:\zabbix\bin\zabbix_agentd.exe -i -c C:\zabbix\conf\zabbix_agentd.win.conf
echo start zabbix services
net start "Zabbix Agent"
echo set zabbix service auto
sc config "Zabbix Agent" start= auto
echo Zabbix agentd Configuration and Install Successful