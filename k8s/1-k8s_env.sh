#/bin/bash


[ `id -u` != '0' ] && \
    { echo -e '\e[32;1m Please run the script as root!!! \e[0m'
      exit 1; }

[ `grep -Po 'CentOS.+release \K\d' /etc/redhat-release` == 7 ] || { echo 'not support this os';exit 2; }

[[ `yum repolist` =~ '!epel/' ]]  || yum install -y epel-release
[[ `rpm -qa` =~ openssl ]] || yum install -y openssl

systemctl is-enabled firewalld && systemctl disable --now firewalld
systemctl is-enabled NetworkManager && systemctl disable --now NetworkManager
systemctl is-enabled dnsmasq && systemctl disable --now dnsmasq

#disabled the selinux
getenforce | grep "Disabled" || {
    setenforce 0
    sed -ri '/^[^#]*SELINUX=/s#=.+$#=disabled#' /etc/selinux/config
}

[ -f '/etc/sysctl.d/k8s.conf' ] && mv /etc/sysctl.d/{,old_}k8s.conf

# set the Kernel forwarding
sed -i '/net.ipv4.ip_forward = 0/d' /etc/sysctl.conf
{
sysctl -a | grep -wq 'net.ipv4.ip_forward = 1' || echo 'net.ipv4.ip_forward = 1'
sysctl -a | grep -wq 'net.bridge.bridge-nf-call-ip6tables = 1' || echo 'net.bridge.bridge-nf-call-ip6tables = 1'
sysctl -a | grep -wq 'net.bridge.bridge-nf-call-iptables = 1' || echo 'net.bridge.bridge-nf-call-iptables = 1'
sysctl -a | grep -wq 'vm.swappiness = 0' || echo 'vm.swappiness = 0'
} > /etc/sysctl.d/k8s.conf
[ ! -s '/etc/sysctl.d/k8s.conf' ] && /bin/rm -f  /etc/sysctl.d/k8s.conf || sysctl -p /etc/sysctl.d/k8s.conf

#turn off the swap
swapoff -a 
sed -ri '/^[^#]*swap/s@^@#@' /etc/fstab

# sync time 
crontab -l | grep -q "ntpdate" || {
    which ntpdate &>/dev/null || {
        yum install ntpdate -y
        ntpdate ntp4.aliyun.com
        echo "*/5 * * * * `which ntpdate` ntp4.aliyun.com >/dev/null 2>&1">/var/spool/cron/root
    }
}


# check kernel version is greater than 4.14，if not then adjust boot sequrence
grub2-editenv  list | grep "(5." || {
    # upgrade kernel to 5.1,--->https://github.com/Lentil1016/kubeadm-ha/issues/19
    rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
    yum --enablerepo=elrepo-kernel install kernel-ml-devel kernel-ml -y
    # grub2-set-default "CentOS Linux (5.1.15-1.el7.elrepo.x86_64) 7 (Core)"
    grub2-set-default 0
    grubby --default-kernel | grep "/boot/vmlinuz-5"
    reboot
}

# reboot to change 5.15 version kernel
# read -p "reboot to take effect [y/n]?" flag
# if [ $flag == "y" ];then
#    reboot
#elif [ $flag == "n" ];then
#    exit 0
#else
#    echo "input error!!! please reboot later"
#    exit 1
#fi
