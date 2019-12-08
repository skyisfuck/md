#!/bin/bash
#

ETCD_VER=v3.3.13

# choose either URL
DOWNLOAD_URL=https://github.com/etcd-io/etcd/releases/download

mkdir -p /usr/local/etcd-${ETCD_VER}/{bin,cfg,ssl}

curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
mkdir /tmp/etcd-${ETCD_VER} -p
tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp/etcd-${ETCD_VER} --strip-components=1
mv /tmp/etcd-${ETCD_VER}/{etcd,etcdctl} /usr/local/etcd/bin/
rm -rf /tmp/etcd-${ETCD_VER}*

ln -s /usr/local/etcd-${ETCD_VER} /usr/local/etcd
/usr/local/etcd/bin/etcd --version
ETCDCTL_API=3 /usr/local/etcd/bin/etcdctl version
