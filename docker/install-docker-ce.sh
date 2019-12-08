#!/bin/bash
#

install(){
    yum install -y yum-utils device-mapper-persistent-data lvm2
    wget -qO /etc/yum.repos.d/docker-ce.repo https://download.docker.com/linux/centos/docker-ce.repo
    yum install -y docker-ce docker-ce-cli containerd.io
    systemctl enable --now docker
    
    curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
}

config(){
    sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
    echo -e "# docker config\nnet.ipv4.ip_forward = 1\nnet.bridge.bridge-nf-call-ip6tables = 1\nnet.bridge.bridge-nf-call-iptables = 1">> /etc/sysctl.conf
    sysctl --system
    mkdir /etc/docker -p
    cat>/etc/docker/daemon.json<<EOF
{
  "registry-mirrors": ["https://fz5yth0r.mirror.aliyuncs.com"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
EOF
    systemctl restart docker
}

install
config
