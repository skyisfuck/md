@echo off 
chcp 65001
rem 获取计算机cpu信息 
echo ------------------------------------------cpu info------------------------------------------
wmic cpu list brief | more
echo ------------------------------------------mem info------------------------------------------
wmic memorychip get Capacity,DeviceLocator,Tag,DataWidth ,Speed ,SerialNumber ,Manufacturer | more
echo -----------------------------------------disk info------------------------------------------
wmic diskdrive get Caption,CreationClassName ,SerialNumber, Signature,Size , Status , StatusInfo | more
echo --------------------------------------logicdisk info-----------------------------------------
wmic logicaldisk get Caption ,FileSystem , FreeSpace, Name,SystemCreationClassName , VolumeSerialNumber | more
echo --------------------------------------baseboard info-----------------------------------------
wmic baseboard get CreationClassName, Manufacturer, Product ,SerialNumber,Status , Tag , Version | more
echo -----------------------------------------bios info------------------------------------------
wmic bios get BIOSVersion,Caption,Manufacturer , Name , OtherTargetOS,ReleaseDate,Status , Version | more
echo ------------------------------------------IdentifyingNumber--------------------------------------------
wmic csproduct get IdentifyingNumber | more
echo ------------------------------------------os info--------------------------------------------
wmic os get Caption,FreePhysicalMemory , FreeSpaceInPagingFiles , InstallDate ,Manufacturer , Name | more
echo;
systeminfo
