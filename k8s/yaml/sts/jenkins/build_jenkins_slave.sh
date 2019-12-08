#!/bin/bash
#

# for example 
# DOCKER_VERSION=18.06.3
DOCKER_VERSION=18.06.3


if [ ! $DOCKER_VERSION ];then
    echo "ERROR: DOCKER_VERSION variable is null";
    exit;
fi;

#[ -f docker-${DOCKER_VERSION}-ce.tgz ]  || wget  https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}-ce.tgz

if [ $? -ne 0 ];then
    echo "download docker file possible failed!! please check!!!"
    exit 1;
fi;

cat<<'EOF'>Dockerfile
FROM jenkins/jnlp-slave:alpine
LABEL MAINTAINER="306647809@qq.com"

USER root
ARG DOCKER_GID=995
ENV DOCKER_VERSION=18.06.3
ENV SSL_DIR /etc/kubernetes/ssl

# 提取 docker 二进制文件 
COPY docker-${DOCKER_VERSION}-ce.tgz /var/tmp/
RUN  tar --strip-components=1 -xvzf /var/tmp/docker-${DOCKER_VERSION}-ce.tgz -C /usr/local/bin \
    && rm -rf /var/tmp/docker-${DOCKER_VERSION}-ce.tgz \
    && chmod -R 775 /usr/local/bin/docker
# 安装 kubectl
COPY kubectl /usr/local/bin/kubectl

# 此处文件均为空文件将在运行时由 ConfigMap 挂载为 Volume 填充真实证书文件
COPY config ${SSL_DIR}/
RUN mkdir -p /root/.kube/ && mkdir -p ${SSL_DIR} \
    touch ${SSL_DIR}/ca.pem \
    touch ${SSL_DIR}/admin.pem \
    touch ${SSL_DIR}/admin-key.pem
RUN export KUBE_CONFIG==${SSL_DIR}/config && kubectl config view 
RUN addgroup -g ${DOCKER_GID} docker && adduser jenkins docker 


# 暴露证书文件所在文件夹，在运行时由 ConfigMap 挂载为 Volume 填充真实证书文件
VOLUME ${SSL_DIR}

USER jenkins:${DOCKER_GID}
EOF

sed -i "s@^ENV DOCKER.*@ENV DOCKER_VERSION=${DOCKER_VERSION}@g" Dockerfile


# 创建configmap 通过serviceaccout 跟 kubeapi 通信，可以不需要下面一行配置
#kubectl create configmap kubectl-cert-cm --from-file=/etc/kubernetes/pki
