#!/bin/bash
###################################
# Description: install zabbix agent 
# Author: ningpeng
# Version: 1.0
# Last Update: 2019.4.2
# system: CentOS 6,7 
###################################


ZabbixServer=192.168.4.62

if  [ $(id -u) -gt 0 ]; then
    echo "please use root run the script!"
    exit 1
fi

# 安装zabbix agent
systemVersion=$(grep -o [0-9] /etc/redhat-release | head -n 1)
if [ $systemVersion -eq 7 ];then
    yum -y install https://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm
elif [ $systemVersion -eq 6 ];then
    yum -y install https://repo.zabbix.com/zabbix/4.0/rhel/6/x86_64/zabbix-release-4.0-1.el6.noarch.rpm
else
    echo "your system is not redhat and centos"
    exit 1
fi;

yum -y install zabbix-agent;

# 配置zabbix agent
cp /etc/zabbix/zabbix_agentd.conf{,.bak}
sed -i "s/Server=.*/Server=$ZabbixServer/" /etc/zabbix/zabbix_agentd.conf
sed -i "s/ServerActive=.*/ServerActive=$ZabbixServer/" /etc/zabbix/zabbix_agentd.conf
sed -i "s/# UnsafeUserParameters=.*/UnsafeUserParameters=1/" /etc/zabbix/zabbix_agentd.conf
sed -i "s/# HostMetadataItem=.*/HostMetadataItem=system.uname/" /etc/zabbix/zabbix_agentd.conf
sed -i "s/# HostMetadata=.*/HostMetadata=LinuxServer/" /etc/zabbix/zabbix_agentd.conf 
sed -i "s/# EnableRemoteCommands=.*/EnableRemoteCommands=1/" /etc/zabbix/zabbix_agentd.conf 
sed -i "s/# LogRemoteCommands=.*/LogRemoteCommands=1/" /etc/zabbix/zabbix_agentd.conf 
sed -i "s/# Timeout=.*/Timeout=30/" /etc/zabbix/zabbix_agentd.conf 
mkdir -p /etc/zabbix/scripts &&  wget -O /etc/zabbix/scripts/linux_hwinfo.sh https://raw.githubusercontent.com/skyisfuck/shell/master/zabbix/linux/linux_hwinfo.sh
echo "UserParameter=linux.hwinfo,/bin/bash /etc/zabbix/scripts/linux_hwinfo.sh" > /etc/zabbix/zabbix_agentd.d/linux_hwinfo.conf

# 安装查看系统软件
rpm -qf `which dmidecode` || yum install dmidecode -y
rpm -qf `which lsscsi` || yum install lsscsi -y
chmod u+s `which dmidecode`

# 防火墙 
if [ $systemVersion -eq 7 ];then
    firewall-cmd --add-port=10050/tcp --permanent
    firewall-cmd --reload
elif [ $systemVersion -eq 6 ];then
    iptables -A INPUT -p tcp --dport 10050 -j ACCEPT
    iptables -A OUTPUT -p tcp --sport 10050 -j ACCEPT
    service iptables save
fi;

# 启动服务
if [ $systemVersion -eq 7 ];then
    systemctl enable zabbix-agent
    systemctl start zabbix-agent
elif [ $systemVersion -eq 6 ];then
    service zabbix-agent save
    chkconfig zabbix-agent on
fi;

