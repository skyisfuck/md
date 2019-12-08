#!/bin/bash
#
#k8s version,如果要安装最新版，则注释下行
export K8S_VER=1.15.3

#选择网络插件（calico 或者 flannel）
export NET_PLUGIN=calico

# 集群各机器 IP 数组
export NODE_IPS=(192.168.100.101 192.168.100.102 192.168.100.103)

# 集群各 IP 对应的主机名数组 (脚本会自动设置以下主机主机名)
export NODE_NAMES=(kubeadm-master kubeadm-node1 kubeadm-node2)

# 集群各机器对应的网卡名
export NODE_NET_NAMES=(ens32 ens32 ens32)

# 集群各master 主机名 数组
export MASTER_NAMES=(kubeadm-master kubeadm-node1 kubeadm-node2)

# 集群各master IP 数组
export MASTER_IPS=(192.168.100.101 192.168.100.102 192.168.100.103)

# 集群各master对应的网卡名
export MASTER_NET_NAMES=(ens32 ens32 ens32)

# 集群各work 主机名 数组 (如果节点既是master又是work，则请注释下行)
# export WORK_NAMES=(kubeadm-master kubeadm-node1 kubeadm-node2)

# 集群各work对应的网卡名 (如果节点既是master又是work，则请注释下行)
# export WORD_NET_NAMES=(ens32 ens32 ens32)

# 集群各work IP 数组 (如果节点既是master又是work，则请注释下行)
# export WORK_IPS=(192.168.100.101 192.168.100.102 192.168.100.103)

# 集群各 IP 对应的机器密码
export NODE_PASS=(redhat redhat redhat)

# kube-apiserver vip地址
export KUBE_APISEVER_VIP="192.168.100.250"

# kube-apiserver 的反向代理(kube-nginx)地址端口
export KUBE_APISERVER="https://192.168.100.250:8443"

## 以下参数一般不需要修改

# 服务网段，部署前路由不可达，部署后集群内路由可达(kube-proxy 保证)
SERVICE_CIDR="10.254.0.0/16"

# Pod 网段，建议 /16 段地址，部署前路由不可达，部署后集群内路由可达(flanneld 保证)
CLUSTER_CIDR="10.244.0.0/16"

# 服务端口范围 (NodePort Range)
export NODE_PORT_RANGE="30000-32767"
