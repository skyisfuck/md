#!/bin/bash
#
HELM_VERSION=${1:-2.14.3}


init_check(){
    kubectl get nodes >/dev/null 2>/dev/null && flag=1
    if [ -z $flag ];then
        echo "ERROR: please run script on k8s master node"
        exit 1
    fi;
}


install(){
    which git || yum install git -y
    # [ -f helm-v${HELM_VERSION}-linux-amd64.tar.gz ] || wget -q  https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz
    [ -f helm-v${HELM_VERSION}-linux-amd64.tar.gz ] || git clone https://gitee.com/skyisfuck/software.git
    mv software/helm*.tar.gz . && rm -rf software
    tar xf helm-v${HELM_VERSION}-linux-amd64.tar.gz

    

    if [ -d linux-amd64 ]; then
        mv linux-amd64/helm /usr/local/bin/helm
        helm completion bash > /root/.helmrc
        echo "source .helmrc" >> /root/.bashrc
        source .bashrc
        docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v${HELM_VERSION}
        kubectl create serviceaccount --namespace kube-system tiller
        kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
        helm init --service-account tiller --upgrade -i registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v${HELM_VERSION} --skip-refresh --dry-run -oyaml >tiller.yaml
        if grep -q "extensions/v1beta1" tiller.yaml;then
            sed -i  "s@extensions/v1beta1@apps/v1@" tiller.yaml
            sed -i '/strategy:/a%      name: tiller' tiller.yaml
            sed -i '/strategy:/a%      app: helm' tiller.yaml
            sed -i '/strategy:/a%    matchLabels:' tiller.yaml
            sed -i '/strategy:/a%  selector:' tiller.yaml
            sed -i 's/^%//' tiller.yaml
        fi
        kubectl apply -f .
        while true;do
            kubectl describe pods -n kube-system -l name=tiller  | grep "PodScheduled" | grep "True" -qi
            if [ $? -ne 0 ];then
                sleep 5;
            else
                break;
            fi
        done
        helm repo remove stable
        # helm repo add stable https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts 阿里云得好久没有更新，所以用下面得微软源
        helm repo add stable  http://mirror.azure.cn/kubernetes/charts/
        helm repo update
        helm repo list
    else
        echo "EROOR: helm-v${HELM_VERSION}-linux-amd64.tar.gz file is not completion" 
        exit 1 
    fi;

}

main(){
    init_check
    install
}

main
