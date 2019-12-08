#!/bin/bash
#
# googlekubernetes源: https://hub.docker.com/u/mirrorgooglecontainers/
# 另外一个googlekubernetes源: docker pull gcr.azk8s.cn/google_containers/pause-amd64:3.0
# 可以通过kubeadm config images list 查看kubeadm需要的镜像
# ————————————————
# 一、gcr.io镜像加速
# 由于众所周知的原因，google镜像在国内是无法拉取的。我们可以使用中科大镜像进行拉取。
# 1.1 使用中科大镜像
# 我们拉取的google镜像是以下形式：
# docker pull gcr.io/xxx/yyy:zzz
# 那么使用中科大镜像，应该是这样拉取：
# docker pull gcr.mirrors.ustc.edu.cn/xxx/yyy:zzz
# 或者使用Azure
# docker pull gcr.azk8s.cn/xxx/yyy:zzz
# ————————————————
# 二、quay.io镜像加速
# 2.1 使用中科大镜像
# 如果我们拉取的quay.io镜像是以下形式：
# docker pull quay.io/xxx/yyy:zzz
# 那么使用中科大镜像，应该是这样拉取：
# docker pull quay.mirrors.ustc.edu.cn/xxx/yyy:zzz
# 或者使用Azure
# docker pull quay.azk8s.cn/xxx/yyy:zzz


set -ex
if [ $# -eq 1 -a $1 == "custom" ];then
    kubeadm config images list 2>/dev/null | sed  's@.*/@export @' | tr ":" "=" | tr "-" "_"   >image.info
    source image.info
    KUBE_VERSION=$kube_apiserver
    PAUSE_VERSION=$pause
    ETCD_VERSION=$etcd
    COREDNS_VERSION=$coredns
    rm -f image.info
else
    KUBE_VERSION=v1.15.3
    PAUSE_VERSION=3.1
    ETCD_VERSION=3.3.10
    COREDNS_VERSION=1.3.1
fi;


docker pull gcr.azk8s.cn/google_containers/kube-apiserver:${KUBE_VERSION}
docker pull gcr.azk8s.cn/google_containers/kube-controller-manager:${KUBE_VERSION}
docker pull gcr.azk8s.cn/google_containers/kube-scheduler:${KUBE_VERSION}
docker pull gcr.azk8s.cn/google_containers/kube-proxy:${KUBE_VERSION}
docker pull gcr.azk8s.cn/google_containers/pause:${PAUSE_VERSION}
docker pull gcr.azk8s.cn/google_containers/etcd:${ETCD_VERSION}
docker pull coredns/coredns:${COREDNS_VERSION}

docker tag gcr.azk8s.cn/google_containers/kube-apiserver:${KUBE_VERSION} k8s.gcr.io/kube-apiserver:${KUBE_VERSION}
docker tag gcr.azk8s.cn/google_containers/kube-controller-manager:${KUBE_VERSION} k8s.gcr.io/kube-controller-manager:${KUBE_VERSION}
docker tag gcr.azk8s.cn/google_containers/kube-scheduler:${KUBE_VERSION} k8s.gcr.io/kube-scheduler:${KUBE_VERSION}
docker tag gcr.azk8s.cn/google_containers/kube-proxy:${KUBE_VERSION}  k8s.gcr.io/kube-proxy:${KUBE_VERSION}
docker tag gcr.azk8s.cn/google_containers/pause:${PAUSE_VERSION}  k8s.gcr.io/pause:${PAUSE_VERSION}
docker tag gcr.azk8s.cn/google_containers/etcd:${ETCD_VERSION}  k8s.gcr.io/etcd:${ETCD_VERSION}
docker tag coredns/coredns:${COREDNS_VERSION} k8s.gcr.io/coredns:${COREDNS_VERSION}

docker rmi gcr.azk8s.cn/google_containers/kube-apiserver:${KUBE_VERSION}
docker rmi gcr.azk8s.cn/google_containers/kube-controller-manager:${KUBE_VERSION}
docker rmi gcr.azk8s.cn/google_containers/kube-scheduler:${KUBE_VERSION}
docker rmi gcr.azk8s.cn/google_containers/kube-proxy:${KUBE_VERSION}
docker rmi gcr.azk8s.cn/google_containers/pause:${PAUSE_VERSION}
docker rmi gcr.azk8s.cn/google_containers/etcd:${ETCD_VERSION}
docker rmi coredns/coredns:${COREDNS_VERSION}
