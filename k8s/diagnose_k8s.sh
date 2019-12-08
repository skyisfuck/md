#!/usr/bin/env bash
set -x
current_dir=$(pwd)
timestamp=$(date +%s)
diagnose_dir=/tmp/diagnose_${timestamp}
mkdir -p $diagnose_dir

run() {
    echo
    echo "-----------------run $@------------------"
    timeout 10s $@
    if [ "$?" != "0" ]; then
        echo "failed to collect info: $@"
    fi
    echo "------------End of ${1}----------------"
}

os_env()
{
    ubu=$(cat /etc/issue|grep -i "ubuntu"|wc -l)
    debian=$(cat /etc/issue|grep -i "debian"|wc -l)
    cet=$(cat /etc/centos-release|grep "CentOS"|wc -l)
    redhat=$(cat /etc/redhat-release|grep "Red Hat"|wc -l)
    alios=$(cat /etc/redhat-release|grep "Alibaba"|wc -l)
    if [ "$ubu" == "1" ];then
        export OS="Ubuntu"
    elif [ "$cet" == "1" ];then
        export OS="CentOS"
    elif [ "$redhat" == "1" ];then
        export OS="RedHat"
    elif [ "$debian" == "1" ];then
        export OS="Debian"
    elif [ "$alios" == "1" ];then
        export OS="AliOS"
    else
       echo "unkown os...   exit"
       exit 1
    fi
}

dist() {
    cat /etc/issue*
}

command_exists() {
    command -v "$@" > /dev/null 2>&1
}

# Service status
service_status() {
    run service firewalld status | tee $diagnose_dir/service_status
    run service ntpd status | tee $diagnose_dir/service_status
}


#system info

system_info() {
    # mkdir -p ${diagnose_dir}/system_info
    run uname -a | tee -a ${diagnose_dir}/system_info
    run uname -r | tee -a ${diagnose_dir}/system_info
    run dist | tee -a ${diagnose_dir}/system_info
    if command_exists lsb_release; then
        run lsb_release | tee -a ${diagnose_dir}/system_info
    fi
    run ulimit -a | tee -a ${diagnose_dir}/system_info
    run sysctl -a | tee -a ${diagnose_dir}/system_info
}

#network
network_info() {
    # mkdir -p ${diagnose_dir}/network_info
    #run ifconfig
    run ip --details ad show | tee -a ${diagnose_dir}/network_info
    run ip --details link show | tee -a ${diagnose_dir}/network_info
    run ip route show | tee -a ${diagnose_dir}/network_info
    run iptables-save | tee -a ${diagnose_dir}/network_info
    netstat -nt | tee -a ${diagnose_dir}/network_info
    netstat -nu | tee -a ${diagnose_dir}/network_info
    netstat -ln | tee -a ${diagnose_dir}/network_info
}




#system status
system_status() {
    #mkdir -p ${diagnose_dir}/system_status
    run uptime | tee -a ${diagnose_dir}/system_status
    run top -b -n 1 | tee -a ${diagnose_dir}/system_status

    run ps -ef | tee -a ${diagnose_dir}/system_status
    run netstat -nt | tee -a ${diagnose_dir}/system_status
    run netstat -nu | tee -a ${diagnose_dir}/system_status
    run netstat -ln | tee -a ${diagnose_dir}/system_status

    run df -h | tee -a ${diagnose_dir}/system_status

    run cat /proc/mounts | tee -a ${diagnose_dir}/system_status

    run pstree -al | tee -a ${diagnose_dir}/system_status

    run lsof | tee -a ${diagnose_dir}/system_status

    (
        cd /proc
        find -maxdepth 1 -type d -name '[0-9]*' \
         -exec bash -c "ls {}/fd/ | wc -l | tr '\n' ' '" \; \
         -printf "fds (PID = %P), command: " \
         -exec bash -c "tr '\0' ' ' < {}/cmdline" \; \
         -exec echo \; | sort -rn | head | tee -a ${diagnose_dir}/system_status
    )
}



# docker status
showdaemon() {
     run ps -ef|grep -E 'dockerd|docker daemon'|grep -v grep| tee -a ${diagnose_dir}/docker_status
}

docker_status() {
    #mkdir -p ${diagnose_dir}/docker_status
    echo "check dockerd process"
    showdaemon
    #docker info
    run docker info | tee -a ${diagnose_dir}/docker_status
    run docker version | tee -a ${diagnose_dir}/docker_status
    sudo kill -SIGUSR1 $(cat /var/run/docker.pid)
    cp /var/run/docker/libcontainerd/containerd/events.log ${diagnose_dir}/containerd_events.log
    sleep 10
    cp /var/run/docker/*.log ${diagnose_dir}

}




showlog() {
    local file=$1
    if [ -f "$file" ]; then
        tail -n 200 $file
    fi
}

#collect log
common_logs() {
    mkdir -p ${diagnose_dir}/logs
    run dmesg -T | tee ${diagnose_dir}/logs/dmesg.log
    cp /var/log/messages ${diagnose_dir}/logs
    pidof systemd && journalctl -u docker.service &> ${diagnose_dir}/logs/docker.log || cp /var/log/upstart/docker.log ${diagnose_dir}/logs/docker.log
}

archive() {
    tar -zcvf ${current_dir}/diagnose_${timestamp}.tar.gz ${diagnose_dir}
    echo "please get diagnose_${timestamp}.tar.gz for diagnostics"
}

varlogmessage(){
    grep cloud-init /var/log/messages > $diagnose_dir/varlogmessage.log
}

cluster_dump(){
    kubectl cluster-info dump > $diagnose_dir/cluster_dump.log
}

events(){
    kubectl get events > $diagnose_dir/events.log
}

core_component() {
    local comp="$1"
    local label="$2"
    mkdir -p $diagnose_dir/cs/$comp/
    local pods=`kubectl get -n kube-system po -l $label=$comp | awk '{print $1}'|grep -v NAME`
    for po in ${pods}
    do
        kubectl logs -n kube-system ${po} &> $diagnose_dir/cs/${comp}/${po}.log
    done
}

etcd() {
    journalctl -u etcd -xe &> $diagnose_dir/cs/etcd.log
}

storageplugins() {
    mkdir -p ${diagnose_dir}/storage/
    cp /var/log/alicloud/* ${diagnose_dir}/storage/
}

pd_collect() {
    os_env
    system_info
    service_status
    network_info
    system_status
    docker_status
    common_logs

    varlogmessage
    core_component "cloud-controller-manager" "app"
    core_component "kube-apiserver" "component"
    core_component "kube-controller-manager" "component"
    core_component "kube-scheduler" "component"
    events
    storageplugins
    etcd
    cluster_dump
    archive
}

pd_collect

echo "请上传 diagnose_${timestamp}.tar.gz"
