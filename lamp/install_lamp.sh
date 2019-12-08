#!/bin/bash
# 离线安装lamp ， 需要下载好lamp和createrepo的软件包
#
[ -f /etc/redhat-release ] || {
	echo "your os is not redhat and centos"
	exit 1
}

read -p "please set you mysql password: " MYSQL_PASSWD
osVersion=$(grep -o "[0-9]" /etc/redhat-release | head -1)

# 关闭selinux
setenforce 0  
sed -i 's#SELINUX=enforcing#SELINUX=disabled#' /etc/selinux/config

# 添加yum 源
mkdir -p /etc/yum.repos.d/bak
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak
tar xf rpm.tar.xz -C /root/
cd /root/rpm/createrepo
rpm -ivh *
cd ..
createrepo lamp

echo -e '[lamp]\nname=lamp\nbaseurl=file:///root/rpm/lamp\ngpgcheck=0'>/etc/yum.repos.d/lamp.repo

# 下载httpd mysqld php
yum install --enablerepo=lamp -y httpd php mysql-community-server


[[ $osVersion -eq 6 ]] && {
	services iptables stop
	chkconfig iptables off
	services httpd start
	services mysqld start
	chkconfig httpd on
	chkconfig mysqld on
} || {
	systemctl disable firewalld
	systemctl stop firewalld
	systemctl start httpd
	systemctl start mysqld
	systemctl enable httpd
	systemctl enable mysqld
}


if [ ! -e /usr/bin/expect ] 
 then  yum install expect -y 
fi
echo '#!/usr/bin/expect
set timeout 60
set password [lindex $argv 0]
spawn mysql_secure_installation
expect {
"enter for none" { send "\r"; exp_continue}
"Y/n" { send "Y\r" ; exp_continue}
"password" { send "$password\r"; exp_continue}
"Cleaning up" { send "\r"}
}
interact ' > mysql_secure_installation.exp 
chmod +x mysql_secure_installation.exp
./mysql_secure_installation.exp $MYSQL_PASSWD 

flag=$(ss -lntup | egrep ":80|:3306" | wc -l)
[[ $flag -eq 2 ]] && {
	echo -e '\n\tlamp install over!!!\n'
}
