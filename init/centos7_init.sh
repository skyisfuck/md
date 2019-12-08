#!/bin/bash
#
hostName=${1}

echo -ne "\\033[0;33m"
cat<<EOF
                                  _oo0oo_
                                 088888880
                                 88" . "88
                                 (| -_- |)
                                  0\\ = /0
                               ___/'---'\\___
                             .' \\\\\\\\|     |// '.
                            / \\\\\\\\|||  :  |||// \\\\
                           /_ ||||| -:- |||||- \\\\
                          |   | \\\\\\\\\\\\  -  /// |   |
                          | \\_|  ''\\---/''  |_/ |
                          \\  .-\\__  '-'  __/-.  /
                        ___'. .'  /--.--\\  '. .'___
                     ."" '<  '.___\\_<|>_/___.' >'  "".
                    | | : '-  \\'.;'\\ _ /';.'/ - ' : | |
                    \\  \\ '_.   \\_ __\\ /__ _/   .-' /  /
                ====='-.____'.___ \\_____/___.-'____.-'=====
                                  '=---='


              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                建议系统                    CentOS7
                建议配置                    2Core4G
                建议磁盘                    >=50G
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
             PS：请尽量使用纯净的CentOS7系统，我们会在服务器安装
    [yum_config iptables_config history system_config ulimit_config sysctl_config]
    
EOF
echo -ne "\\033[m"

error_print(){
    echo -e "\033[31m\t$1\033[0m"
}

right_print(){
    echo -e "\033[32m\t$1\033[0m"
}

init_check(){
    #判断是否为root用，platform是否为X64
    if  [ $(id -u) -gt 0 ]; then
        error_print "please use root run the script!"
        exit 1
    fi

    #add hostname
    if [ "${hostName}" == "" ];then
       ##  error_print "The host name is empty."
       ##  exit 1
       :
    else
        hostnamectl set-hostname ${hostName}
    fi

    platform=`uname -i`
    osversion=`cat /etc/redhat-release | awk '{print $1}'`
    local_ip=$(ip a | awk -F'[ /]+' '/inet .*brd/{print $3}')
    

    if [[ $platform != "x86_64" ||  $osversion != "CentOS" ]];then
        error_print "Error this script is only for 64bit and CentOS Operating System !"
        exit 1
    fi
    right_print "The platform is ok"

    cat << EOF
     +--------------------------------------------------------------+  
                     Welcome to  System init 
                     local ip: ${local_ip}  
                     hostname: $(hostname)      
     +--------------------------------------------------------------+  
EOF

}


#configure yum source
yum_config(){
    yum install wget epel-release -y
    cd /etc/yum.repos.d/ && mkdir bak && mv -f *.repo bak/
    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
    sed -i '/aliyuncs/d' /etc/yum.repos.d/CentOS-Base.repo
    wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
    yum clean all && yum makecache
    yum -y install lrzsz curl unzip wget vim bash-completion ntpdate
}

#firewalld
iptables_config(){
    systemctl is-enabled firewalld && systemctl disable --now firewalld
    systemctl is-enabled NetworkManager && systemctl disable --now NetworkManager
#    yum install iptables-services -y
#    systemctl enable iptables
#    systemctl start iptables
#    iptables -F
#    service iptables save
}

#system config
system_config(){
    setenforce 0
    sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
    sed -i "s/#UseDNS yes/UseDNS no/" /etc/ssh/sshd_config
    sed -i "s/GSSAPIAuthentication .*/GSSAPIAuthentication no/" /etc/ssh/sshd_config
    timedatectl set-local-rtc 1 && timedatectl set-timezone Asia/Shanghai
#    yum -y install chrony && systemctl start chronyd.service && systemctl enable chronyd.service 
    ntpdate ntp4.aliyun.com && hwclock -w
    echo "*/5 * * * * /usr/sbin/ntpdate ntp4.aliyun.com 1>/dev/null 2>&1" > /var/spool/cron/root
    if ! grep -q "PS1" /etc/profile;then
    	echo '## PS1 config' >>/etc/profile
	echo "export PS1='\[\e[1;36m\][\u@\h \W]$ \[\e[0m\]'" >> /etc/profile >> /etc/profile;
    fi
}

ulimit_config(){
    ulimit -SHn 102400
    cat >> /etc/security/limits.conf << EOF
*           soft   nofile       102400
*           hard   nofile       102400
*           soft   nproc        102400
*           hard   nproc        102400
EOF

}

history(){
	if ! grep "HISTTIMEFORMAT" /etc/profile >/dev/null 2>&1
	then echo '
	UserIP=$(who -u am i | cut -d"("  -f 2 | sed -e "s/[()]//g")
	export HISTTIMEFORMAT="[%F %T] [`whoami`] [${UserIP}] " ' >> /etc/profile;
	fi
}

#set sysctl
sysctl_config(){
    cp /etc/sysctl.conf /etc/sysctl.conf.bak
    cat > /etc/sysctl.conf << EOF
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 262144
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 30
net.ipv4.ip_local_port_range = 1024 65535

EOF
    /sbin/sysctl -p
    right_print "sysctl set OK!!"
}

main(){
    init_check
    yum_config
    iptables_config
    history
    system_config
    ulimit_config
    sysctl_config
}
main

cat << EOF
 +--------------------------------------------------------------+  
 |                === System init Finished ===                  |  
 +--------------------------------------------------------------+  
EOF
sleep 3
right_print "Please reboot your system!"
