#!/bin/bash
##########################Test Setting######################################
#定义日志文件
Test_log=/var/log/Storage_System_Stress_result.log
#
#定义脚本运行时间
#
Runtime=12h
read -p "Please enter the stress run time(default:12h):" Runtime
if [ -z $Runtime ]
	then
		Runtime=12h
	else
		Runtime=$Runtime
fi
#
#判断是否安装stress
which stress 2> /dev/null 1> /dev/null
if [ $? -eq '0' ]
	then
		stress --version
	else
		echo -e "\033[31m [+]Stress Error,No stress installed,please install stress! \033[0m"
		exit
fi		
#=================磁盘部分======================
#===============================================
#===============================================
#
#获取所有磁盘
lsscsi |awk '{print $NF}' | grep -v sr[0-9] > all_disk.data
#排除不要有测试的磁盘（如系统盘）
disk=`blkid | grep "TYPE=\"isw_raid_member\"" | awk -F ":" '{print $1}' | cut -d "/" -f 3`
#将不要要测试的磁盘从all_disk.data中删除
echo "$disk" | xargs -n 1 | xargs -I {} echo "\\/dev\\/{}"  > undisk.log
for i in `cat undisk.log`
  do
    sed -i "${i}/d" all_disk.data
  done

#cat all_disk.data | xargs -I {} echo --filename={} |xargs > all_disk1.data
#
#filename=`cat all_disk1.data`
#
#
cat all_disk.data | awk -F "/" '{print $NF}' > filename1

#
for diskname in `cat filename1`
do
{
#关闭cache
echo 3 > /proc/sys/vm/drop_caches
dd if=/dev/zero of=/dev/$diskname bs=32768 count=1 >/dev/null 2>&1
parted /dev/$diskname >/dev/null 2>&1  <<FORMAT               
mklabel gpt
mkpart primary 2048s 100%
quit
FORMAT
sleep 2
mkfs.ext4 -T largefile  /dev/"$diskname"1 >/dev/null 2>&1   #格式化磁盘
sleep 2
mkdir -p /mnt/$diskname
mount -t ext4 /dev/"$diskname"1 /mnt/$diskname
cd /mnt/$diskname/
echo "$diskname Stress is running,please waitting..."
sleep 2
stress --hdd 1 --hdd-bytes 60G --timeout $Runtime > stress.log  2>&1 
}&
done
#删除临时文件
rm -rf all_disk.data undisk.log all_disk1.data
#
#
wait
sleep 2
echo "All disk Stress is complete,please waitting..."
echo " " > $Test_log
for i in `cat filename1`
do
{
echo "####################The $i test result:####################" >> $Test_log
cat "/mnt/$i/stress.log" >> $Test_log
}
done

echo "####################lsblk####################" >> $Test_log
lsblk >> $Test_log


echo "####################dmesg####################" >> $Test_log
dmesg >> $Test_log

echo "Remove test disk..."
for diskname in `cat filename1`
do
{
sleep 2
umount /mnt/$diskname
parted /dev/$diskname >/dev/null 2>&1  <<FORMAT
rm 1
quit
FORMAT
}
done
rm -rf /mnt/*
echo "The test complete"

