#!/usr/bin/ksh
export LANG=en_US

echo ------OS Version------
oslevel -r

echo ------System configure------
prtconf
echo ------Lpar Information------
lparstat -i
echo ------System Information------
lscfg -vp

echo ------Disks------
lsdev -Cc disk

echo ------LVM------
lsvg -o |lsvg -li
lsvg -o |lsvg -pi
df -m

echo ------Adapter------
lsdev -Cc adapter
lsslot -c pci
lsslot -c phb

echo ------Network------
ifconfig -a
netstat -i

echo ------Microcode------
lsmcode -A

echo ------HACMP------
lssrc -g cluster >/dev/null
if [ $? -eq 0 ]
then
lssrc -ls clstrmgrES
/usr/es/sbin/cluster/utilities/cltopinfo
#lscluster -m
fi

echo ------JAVA------ 
java -version 2>/dev/null
if [ $? -eq 0 ];then
      java -version 2>&1
fi

echo ------Database------
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
conn / as sysdba
select * from v\$version;
quit
EOF
fi

echo ------Midware------

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

dbinst=`ps -ef |grep -i "weblogic.NodeManager"|grep -v "grep" |awk '{print $1}'`>/dev/null
if [ -n "$dbinst" ]; then
   echo "MidWare: WebLogic"
   su - $webinst -c "cd $WLS_HOME/server/bin;./setWLSEnv.sh;java -cp lib/weblogic.jar weblogic.version -verbose"
fi 
echo ------END
