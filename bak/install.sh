#!/bin/bash
#
source /etc/profile

Usage(){
    echo -e "Usage: $0 <flask_main.py ---> \033[31mabsolute path\033[0m> <flask_api.py ---> \033[31mabsolute path\033[0m>"
    exit 1
}

error_print(){
    echo -e "\033[31m\t$1\033[0m"
    exit 1
}

right_print(){
    echo -e "\033[32m\t$1\033[0m"
}

init_check(){
    [ $# -lt 2 ] &&  Usage

    if  [ $(id -u) -gt 0 ]; then
        error_print "please use root run the script!"
    fi;

    if [ ${1:0:1} != "/" -o ${2:0:1} != "/" ];then
        Usage
    fi;

    if [ ! -e $1 -o ! -e $2 ];then
        error_print "$1 or $2 file is not exsits"
    fi;
    
    which crontab &>/dev/null || {
        error_print "cronie software is not install,please install cronie software"
    }
    systemctl status crond &>/dev/null || {
        systemctl start crond  || error_print "crond service start error,please check crond service"
    }
    
    systemctl is-enabled crond &>/dev/null || {
        systemctl enable crond || error_print "crond service start on boot error,please check crond service"
    }
}

config(){
    [ ! -e /usr/local/sbin ] && mkdir -p /usr/local/sbin
    [ -e ./autoExec.sh ] || error_print "current directory is not exsits autoExec.sh file"
    echo '*/5 * * * * /bin/bash /usr/local/sbin/autoExec.sh' > /var/spool/cron/root
    sed -ri "/^flask_main=/s@(flask_main=).*@\1$1@" ./autoExec.sh
    sed -ri "/^flask_api=/s@(flask_api=).*@\1$2@" ./autoExec.sh
    mv ./autoExec.sh /usr/local/sbin
}

over_check(){
    crontab -l | grep "autoExec.sh" &>/dev/null && right_print "install over !!!" || error_print "install error, please check crontab!!!"
}

init_check $@
config $@
over_check
