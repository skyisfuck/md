#!/bin/bash

[ $# -lt 1 ] && {
    echo "Usage:$0 [k8s-release-version]"
    echo -e "\nThe latest version is as follows"
    curl -so - https://github.com/kubernetes/kubernetes/tags | awk -F [/\"] '/<a href=\"\/kubernetes\/kubernetes\/releases\/tag/{print $(NF-1)}'
    exit 1
}

# 216.58.200.240
grep -q "storage.googleapis.com" /etc/hosts || echo "216.58.200.48 storage.googleapis.com" >> /etc/hosts
wget https://storage.googleapis.com/kubernetes-release/release/${1}/kubernetes-server-linux-amd64.tar.gz
