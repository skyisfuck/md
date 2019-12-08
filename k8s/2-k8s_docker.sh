#!/bin/bash
#

# check path
curl -s https://raw.githubusercontent.com/docker/docker/master/contrib/check-config.sh | bash



# install docker
export VERSION=18.06
curl -fsSL "https://get.docker.com/" | bash -s -- --mirror Aliyun

#install(){
# yum install -y yum-utils device-mapper-persistent-data lvm2
# yum-config-manager \
# --add-repo \
# https://download.docker.com/linux/centos/docker-ce.repo
# yum makecache fast
# yum install -y docker-ce
#}


# configure docker
# sed -i "13i ExecStartPost=/usr/sbin/iptables -P FORWARD ACCEPT" /usr/lib/systemd/system/docker.service
mkdir -p /etc/docker/
cat>/etc/docker/daemon.json<<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "registry-mirrors": ["https://fz5yth0r.mirror.aliyuncs.com"],
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
EOF

yum install -y epel-release bash-completion && cp /usr/share/bash-completion/completions/docker /etc/bash_completion.d/
 
# start docker
systemctl daemon-reload
systemctl enable --now docker

