#!/bin/bash
#
ISTIO_VERSION=1.3.0 

blue_print(){
    echo -e "\033[34m$1\033[0m"
}

init_check(){
    kubectl get nodes >/dev/null 2>/dev/null && flag=1
    if [ -z $flag ];then
        echo "ERROR: please run script on k8s master node"
        exit 1
    fi;
}


download(){
    curl -L https://git.io/getLatestIstio | ISTIO_VERSION=${ISTIO_VERSION} sh -
    if [ $? -ne 0 ];then
        sleep 1
        download
    fi;
}

install_istio(){
    cd istio-${ISTIO_VERSION}
    which helm || {
        echo "helm is not install, please install helm before istio"
        exit 1
    }
    kubectl create ns istio-system
    
    helm template install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl apply -f -
    
    CRD_COUNT=0
    until [ ${CRD_COUNT} -eq 23 ];do
         CRD_COUNT=$(kubectl get crds | grep 'istio.io' | wc -l)
         sleep 5
    done;

    sed -i 's/type: LoadBalancer/type: NodePort/' install/kubernetes/helm/istio/charts/gateways/values.yaml
    helm template install/kubernetes/helm/istio --name istio --namespace istio-system | kubectl apply -f -
    blue_print "       if you want to custom istio component,please edit $（pwd）/install/kubernetes/helm/istio/values.yaml file,"
    blue_print "       and helm template $(pwd)/install/kubernetes/helm/istio/ --name istio --namespace istio-system | kubectl apply -f - "
    blue_print "       if you want to uninstall istio, you can 'kubectl delete ns istio-system'"
}


main(){
    init_check
    mkdir /opt/work -p
    cd /opt/work
    download
    install_istio
}

main
