############################################
## Author: xiongjunfeng
## For: Auto install zabbix-agent
## Version: 2.0
## PowerShell: 4.0
## System: Windows 2012 R2
############################################
# wget SSL 证书问题
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 创建目录
$localpath = "c:\ansible"
mkdir $localpath
cd $localpath

# 下载脚本
$url = "https://github.com/ansible/ansible/raw/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
wget -outfile $localpath\ConfigureRemotingForAnsible.ps1 $url

# 安全策略
Set-ExecutionPolicy BYPASS
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force

# 执行脚本
.\ConfigureRemotingForAnsible.ps1 -SkipNetworkProfileCheck

# 防火墙
netsh advfirewall firewall add rule name="Win-RM-HTTP" dir=in localport=5985 protocol=TCP action=allow

# 删除脚本
cd C:\
Remove-Item $localpath -recurse

# 启动并查看服务状态
winrm quickconfig
winrm e winrm/config/listener

# 允许非加密
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
