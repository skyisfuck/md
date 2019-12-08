@echo off
if "%1"=="" (
echo Usage: hmc-cfg IP
goto end
)
if exist log\%1
echo ------ HMC IPaddr ------ >log\HMC_%1.txt
echo HMC IP:%1 >>HMC_%1.txt
ssh hscroot@%1 uname -a >>HMC_%1.txt
echo ------ HMC Version ------ >>HMC_%1.txt
ssh hscroot@%1 lshmc -V -F --header >>HMC_%1.txt
echo ------ HMC info ------ >>HMC_%1.txt
ssh hscroot@%1 lshmc -v -F --header >>HMC_%1.txt
echo ------ HMC Network ------ >>HMC_%1.txt
ssh hscroot@%1 lshmc -n -F --header >>HMC_%1.txt
echo ------ HMC Managed Power System ------ >>HMC_%1.txt
ssh hscroot@%1 lssyscfg -r sys -F --header >>HMC_%1.txt
echo ------ HMC All Logical Partitions ------ >>HMC_%1.txt
ssh hscroot@%1 lsaccfg -t resource --filter "resource_type=lpar" >>HMC_%1.txt
