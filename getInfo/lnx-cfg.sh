#!/bin/bash
 
function getCpuStatus(){
    Physical_CPUs=$(grep "physical id" /proc/cpuinfo| sort | uniq | wc -l)
    Virt_CPUs=$(grep "processor" /proc/cpuinfo | wc -l)
    CPU_Kernels=$(grep "cores" /proc/cpuinfo|uniq| awk -F ': ' '{print $2}')
    CPU_Type=$(grep "model name" /proc/cpuinfo | awk -F ': ' '{print $2}' | sort | uniq)
    CPU_Arch=$(uname -m)
    echo "物理CPU个数:$Physical_CPUs"
    echo "逻辑CPU个数:$Virt_CPUs"
    echo "每CPU核心数:$CPU_Kernels"
    echo "    CPU型号:$CPU_Type"
    echo "    CPU架构:$CPU_Arch"
}
 
function getSystemStatus(){
    if [ -e /etc/sysconfig/i18n ];then
        default_LANG="$(grep "LANG=" /etc/sysconfig/i18n | grep -v "^#" | awk -F '"' '{print $2}')"
    else
        default_LANG=$LANG
    fi
    export LANG="en_US.UTF-8"

    echo " 发行版本："
    cat /etc/redhat-release 2>/dev/null 
    if (($? != 0)); then
    cat /etc/SuSE-release   2>/dev/null
    fi

    Kernel=$(uname -r)
    OS=$(uname -o)
    Hostname=$(uname -n)
    HostnameIP=$(hostname -i)
    LastReboot=$(who -b | awk '{print $3,$4}')
    uptime=$(uptime | sed 's/.*up \([^,]*\), .*/\1/')
    echo "     系统：$OS"
    echo "     内核：$Kernel"
    echo "   主机名：$Hostname"
    echo "   IP地址：$HostnameIP"
    echo "语言/编码：$default_LANG"
    echo " 当前时间：$(date +'%F %T')"
    echo " 最后启动：$LastReboot"
    echo " 运行时间：$uptime"
}
  
function getNetworkStatus(){
    ifconfig -a
    GATEWAY=$(ip route | grep default | awk '{print $3}')
    DNS=$(grep nameserver /etc/resolv.conf| grep -v "#" | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')
    echo "网关：$GATEWAY "
    echo " DNS：$DNS"
}
 
function getJDKStatus(){
    java -version 2>/dev/null
    if [ $? -eq 0 ];then
        java -version 2>&1
    fi
    }

function getDBinfo(){
dbinst=`ps -ef |grep -i db2sysc|grep -v "grep" |awk '{print $1}'` >/dev/null
if [ -n "$dbinst" ]; then
   echo "Database: DB2"
   su - $dbinst -c "db2level"
fi

dbinst= `ps -ef |grep -i mysqld|grep -v "grep" |awk '{print $1}'` >/dev/null
if [ -n "$dbinst" ]; then
   echo "Database: MySQL"
   mysql -V
fi

dbinst=`ps -ef |grep -i "ora_pmon_"|grep -v "grep" |awk '{print $1}'`>/dev/null
if [ -n "$dbinst" ]; then
echo "Database: Oracle"
su - $dbinst -c "sqlplus -s /nolog"<<EOF
conn /as sysdba
select * from v\$version;
quit
EOF
fi
}

function getMidinfo(){
dspmq >/dev/null 2>&1
if (($? == 0)); then
   echo "MidWare: IBM MQSeries"
   dspmqver
fi

ls /usr/IBM/WebSphere/AppServer/bin/versionInfo.sh >/dev/null 2>&1
if (($? == 0)); then
   echo "MidWare: IBM WAS"
   /usr/IBM/WebSphere/AppServer/bin/versionInfo.sh
fi

dbinst=`ps -ef |grep -i "weblogic.NodeManager"|grep -v "grep" |awk '{print $1}'`>/dev/null 2>&1
if [ -n "$dbinst" ]; then
   echo "MidWare: WebLogic"
   su - $webinst -c "cd $WLS_HOME/server/bin;./setWLSEnv.sh;java -cp lib/weblogic.jar weblogic.version -verbose"
fi
}


echo "------System Info------"
dmidecode -q -t 0
dmidecode -q -t 1
dmidecode -q -t 3
getSystemStatus
echo "------CPU Info------"
getCpuStatus
dmidecode -q -t 4
echo "------Memory Info------"
free 
dmidecode -q -t 16
dmidecode -q -t 17
echo "------Disk Info------"
fdisk -l
echo "------Network------"
getNetworkStatus
echo "------System Slots------"
dmidecode -q -t 9
echo "------Power Supply------"
dmidecode -q -t 39
echo "------JAVA------"
getJDKStatus
echo "------DB------"
getDBinfo
echo "------Mid------"
getMidinfo
echo "------END------"
