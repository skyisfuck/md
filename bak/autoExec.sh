#!/bin/bash
#
. /etc/profile

flask_main=/root/test1.py
flask_api=/root/test2.py

flask_main_check(){
    flask_main_statu=$(ps -ef | grep "$flask_main" | grep -v "grep" | wc -l)
    if [ $flask_main_statu -lt 1 ];then
        [ -e $(dirname $flask_main)/flask_main.log ] && mv $(dirname $flask_main)/flask_main.log{,`date +%Y%m%d%H%M`} 
        nohup python3 $flask_main  >$(dirname $flask_main)/flask_main.log 2>&1 &
    fi;
}

flask_api_check(){
    flask_api_statu=$(ps -ef | grep "$flask_api" | grep -v "grep" | wc -l)
    if [ $flask_api_statu -lt 1 ];then
        [ -e $(dirname $flask_api)/flask_api.log ] && mv $(dirname $flask_api)/flask_api.log{,`date +%Y%m%d%H%M`} 
        nohup python3 $flask_api  >$(dirname $flask_api)/flask_api.log 2>&1 &
    fi;
}

flask_main_check
flask_api_check
