############################################
# Author: ningpeng
# Description: install zabbix agent for win2012 R2 
# Version: 1.0
# Last Update: 2019.4.2
# System: Windows 2012 R2
##############################################

$ZabbixServer="192.168.4.62"
$ZabbixVersion="4.0.5"


# SSL 证书问题
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 判断系统类型
$sysinfo=(systeminfo.exe)[14]
$sysinfonew=$sysinfo.Replace("系统类型:         ","")

# 下载安装文件
if ($sysinfonew -like "x64-based PC" ){
    wget -OutFile C:\zabbix_agent.zip https://www.zabbix.com/downloads/"$ZabbixVersion"/zabbix_agents-"$ZabbixVersion"-win-amd64.zip
}else {
    wget -OutFile C:\zabbix_agent.zip https://www.zabbix.com/downloads/"$ZabbixVersion"/zabbix_agents-"$ZabbixVersion"-win-i386.zip
}


# 解压函数传入 压缩文件路径,解压路径
Function Unzip-File()
{
    param([string]$ZipFile,[string]$TargetFolder)
    # 如果文件夹不存在则创建
    if(!(Test-Path $TargetFolder))
    {
        mkdir $TargetFolder
    }
    $shellApp = New-Object -ComObject Shell.Application
    $files = $shellApp.NameSpace($ZipFile).Items()
    $shellApp.NameSpace($TargetFolder).CopyHere($files)
}
# 将安装文件解压
Unzip-File -ZipFile C:\zabbix_agent.zip -TargetFolder C:\zabbix_agent

# 重命名默认配置文件
mv C:\zabbix_agent\conf\zabbix_agentd.win.conf C:\zabbix_agent\conf\zabbix_agentd.win.conf.bak

# 创建配置文件
$hostname=hostname
Add-Content -value "LogFile=C:\zabbix_agent\zabbix.log" C:\zabbix_agent\conf\zabbix_agentd.win.conf
Add-Content -value "Server=$ZabbixServer" C:\zabbix_agent\conf\zabbix_agentd.win.conf
Add-Content -value "ServerActive=$ZabbixServer" C:\zabbix_agent\conf\zabbix_agentd.win.conf 
Add-Content -value "HostMetadataItem=system.uname" C:\zabbix_agent\conf\zabbix_agentd.win.conf 
Add-Content -value "HostMetadata=WindowsServer" C:\zabbix_agent\conf\zabbix_agentd.win.conf
Add-Content -value "UnsafeUserParameters=1" C:\zabbix_agent\conf\zabbix_agentd.win.conf
Add-Content -value "UserParameter=win.hwinfo,call c:\zabbix_agent\scripts\hwinfo.bat" C:\zabbix_agent\conf\zabbix_agentd.win.conf    
Add-Content -value "ServerActive=$ZabbixServer" C:\zabbix_agent\conf\zabbix_agentd.win.conf
Add-Content -value "EnableRemoteCommands=1" C:\zabbix_agent\conf\zabbix_agentd.win.conf    
Add-Content -value "LogRemoteCommands=1" C:\zabbix_agent\conf\zabbix_agentd.win.conf    
Add-Content -value "Timeout=30" C:\zabbix_agent\conf\zabbix_agentd.win.conf   

# 下载硬件获取脚本
if(!(Test-Path c:\zabbix_agent\scripts))
{
    mkdir c:\zabbix_agent\scripts
}
wget -OutFile C:\zabbix_agent\scripts\hwinfo.bat https://raw.githubusercontent.com/skyisfuck/shell/master/zabbix/win/hwinfo.bat


# 注册服务
C:\zabbix_agent\bin\zabbix_agentd.exe --config C:\zabbix_agent\conf\zabbix_agentd.win.conf --install


# 防火墙
netsh advfirewall firewall add rule name="Zabbix-Agent" dir=in localport=10050 protocol=TCP action=allow

# 启动服务
Start-Service "Zabbix Agent"

# 删除安装包
rm C:\zabbix_agent.zip
