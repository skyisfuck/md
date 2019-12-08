#!/bin/bash
#
set -ex

#    kubeadm init主要执行了以下操作：
#    [init]：指定版本进行初始化操作
#    [preflight] ：初始化前的检查和下载所需要的Docker镜像文件
#    [kubelet-start] ：生成kubelet的配置文件”/var/lib/kubelet/config.yaml”，没有这个文件kubelet无法启动，所以初始化之前的kubelet实际上启动失败。
#    [certificates]：生成Kubernetes使用的证书，存放在/etc/kubernetes/pki目录中。
#    [kubeconfig] ：生成 KubeConfig 文件，存放在/etc/kubernetes目录中，组件之间通信需要使用对应文件。
#    [control-plane]：使用/etc/kubernetes/manifest目录下的YAML文件，安装 Master 组件。
#    [etcd]：使用/etc/kubernetes/manifest/etcd.yaml安装Etcd服务。
#    [wait-control-plane]：等待control-plan部署的Master组件启动。
#    [apiclient]：检查Master组件服务状态。
#    [uploadconfig]：更新配置
#    [kubelet]：使用configMap配置kubelet。
#    [patchnode]：更新CNI信息到Node上，通过注释的方式记录。
#    [mark-control-plane]：为当前节点打标签，打了角色Master，和不可调度标签，这样默认就不会使用Master节点来运行Pod。
#    [bootstrap-token]：生成token记录下来，后边使用kubeadm join往集群中添加节点时会用到
#    [addons]：安装附加组件CoreDNS和kube-proxy 

[ -f environment.sh ] && . environment.sh || {
    echo "ERROR: no environment.sh file";
    exit 1
}

yellow_print(){
    echo -e "\033[33m$1\033[0m"
}

blue_print(){
    echo -e "\033[34m$1\033[0m"
}

init_env_config(){
    cd /opt/work
    # add host config
    for i in $(seq 0 $((${#NODE_NAMES[@]}-1)));do
        yellow_print ">>> ${NODE_NAMES[$i]}  add host config"
        echo "${NODE_IPS[$i]} ${NODE_NAMES[$i]}">>/etc/hosts;
    done

    # distribute ssh master key
    which sshpass || yum install sshpass -y
    ssh-keygen -t rsa -P '' -f /root/.ssh/id_rsa
    for i in $(seq 0 $((${#NODE_NAMES[@]}-1)));do
        yellow_print ">>> ${NODE_NAMES[$i]} distribute ssh master key"
        sshpass -p "${NODE_PASS[$i]}" scp -o StrictHostKeyChecking=no /etc/hosts root@${NODE_IPS[$i]}:/etc/hosts
        sshpass -p "${NODE_PASS[$i]}" ssh-copy-id -o StrictHostKeyChecking=no root@${NODE_NAMES[$i]}
        ssh ${NODE_NAMES[$i]} hostnamectl set-hostname ${NODE_NAMES[$i]}
    done;
  
    # centos7_init_env_config
    for i in $(seq 0 $((${#NODE_NAMES[@]}-1)));do
        yellow_print ">>> ${NODE_NAMES[$i]} centos7_init_env_config"
        ssh ${NODE_NAMES[$i]} "wget https://raw.githubusercontent.com/skyisfuck/shell/master/init/centos7_init.sh; bash centos7_init.sh; rm -f centos7_init.sh" 
    done;

    # upgrade kernel to 5.1
    for i in $(seq $((${#NODE_NAMES[@]}-1)) -1 0);do
        yellow_print ">>> ${NODE_NAMES[$i]} upgrade kernel ot 5.1"
        ssh ${NODE_NAMES[$i]} "wget https://raw.githubusercontent.com/skyisfuck/shell/master/k8s/1-k8s_env.sh; bash 1-k8s_env.sh" || ls >/dev/null 2>/dev/null
    done;
}

install_docker_ipvs(){
    cd /opt/work
    for i in $(seq 0 $((${#NODE_NAMES[@]}-1)));do
        yellow_print ">>> ${NODE_NAMES[$i]} install docker 18.06 and ipvs module"
        ssh ${NODE_NAMES[$i]} "wget https://raw.githubusercontent.com/skyisfuck/shell/master/k8s/2-k8s_docker.sh; bash 2-k8s_docker.sh; rm -f *-k8s_*.sh" 
        ssh ${NODE_NAMES[$i]} "wget https://raw.githubusercontent.com/skyisfuck/shell/master/k8s/2-k8s_ipvs.sh; bash 2-k8s_ipvs.sh; rm -f 2-k8s_ipvs.sh" 
    done;
}

install_k8s(){
    cd /opt/work
        cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

    for i in $(seq 0 $((${#NODE_NAMES[@]}-1)));do
        yellow_print ">>> ${NODE_NAMES[$i]} install kubeadm kubelet kubectl"
        scp /etc/yum.repos.d/kubernetes.repo ${NODE_NAMES[$i]}:/etc/yum.repos.d/
        if [ $K8S_VER ];then
            ssh ${NODE_NAMES[$i]} "yum install -y kubelet-${K8S_VER} kubeadm-${K8S_VER} kubectl-${K8S_VER}"
        else
            ssh ${NODE_NAMES[$i]} "yum install -y kubelet kubeadm kubectl"
        fi;
        ssh ${NODE_NAMES[$i]} "systemctl enable kubelet && systemctl start kubelet"
    done;
}

install_haproxy_keepalived(){
    cd /opt/work
    ##### generate keepalived configure file 
    for i in {0..1};do
        yellow_print ">>> ${MASTER_NAMES[$i]} generate keepalived configure file"
        if [ $i -eq 0 ];then
            PRIORITY=100
            STATE=MASTER
            INTERFACE=${MASTER_NET_NAMES[$i]}
            ROUTER_ID=${MASTER_NAMES[$i]}
        else
            PRIORITY=90
            STATE=BACKUP
            INTERFACE=${MASTER_NET_NAMES[$i]}
            ROUTER_ID=${MASTER_NAMES[$i]}
        fi

        cat<<EOF>/tmp/keepalived-${i}.conf
! Configuratile for keepalived
global_defs {
    notification_email {
        306647809@qq.com
    }
    notification_email_from keepalived@k8s.com
    smtp_server 127.0.0.1
    smtp_connect_timeout 30
    router_id ${ROUTER_ID}
}

vrrp_script check_apiserver {
    script "/etc/keepalived/check_apiserver"
    interval 5
    weight -20
    fall 3
    rise 1
}

vrrp_instance VIP_250 {
    state ${STATE}
    interface ${INTERFACE}
    virtual_router_id 250
    priority ${PRIORITY}
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 890iop
    }

    track_script {
        check_apiserver
    }

    virtual_ipaddress {
        ${KUBE_APISEVER_VIP}
    }
}
EOF

    done

    ##### generate keepalived health check configure file 

    cat<<'EOF'>/tmp/check_apiserver
#!/bin/bash
curl 127.0.0.1:8080 &>/dev/null
if [ $? -eq 0 ];then
    exit 0
else
    #systemctl stop keepalived
    exit 1
fi
EOF
    chmod 755 /tmp/check_apiserver

    cat<<EOF>/tmp/haproxy.cfg
global
        chroot  /var/lib/haproxy
        daemon
        group haproxy
        user haproxy
#        log warning
        pidfile /var/lib/haproxy.pid
        maxconn 20000
        spread-checks 3
        nbproc 8

defaults
        log     global
        mode    tcp
        retries 3
        option redispatch

listen https-apiserver
        bind 0.0.0.0:8443
        mode tcp
        balance roundrobin
        timeout server 900s
        timeout connect 15s

        server ${MASTER_NAMES[0]} ${MASTER_IPS[0]}:6443 check port 6443 inter 5000 fall 5
        server ${MASTER_NAMES[1]} ${MASTER_IPS[1]}:6443 check port 6443 inter 5000 fall 5
        server ${MASTER_NAMES[2]} ${MASTER_IPS[2]}:6443 check port 6443 inter 5000 fall 5
EOF

    

    for i in $(seq 0 1);do
        yellow_print ">>> ${MASTER_NAMES[$i]} install haproxy keepalived and configure"
        ssh ${NODE_NAMES[$i]} "yum install -y keepalived haproxy"
        ssh ${NODE_NAMES[$i]} "systemctl enable --now keepalived haproxy"
        scp /tmp/check_apiserver ${NODE_NAMES[$i]}:/etc/keepalived/
        scp /tmp/keepalived-${i}.conf ${NODE_NAMES[$i]}:/etc/keepalived/keepalived.conf
        scp /tmp/haproxy.cfg ${NODE_NAMES[$i]}:/etc/haproxy/
        ssh ${NODE_NAMES[$i]} "systemctl restart keepalived haproxy"
    done;
    
    rm -f /tmp/{check_apiserver,haproxy.cfg,keepalived*}

}

download_k8s_image(){
    yellow_print ">>> ${NODE_NAMES[$i]} download k8s image"
    cd /opt/work
    wget https://raw.githubusercontent.com/skyisfuck/shell/master/k8s/download_k8s_image.sh;bash download_k8s_image.sh custom; rm -f download_k8s_image.sh
    mkdir -p /opt/work/image && cd /opt/work/image
    kubeadm config images list   2>/dev/null   >image.info
        sed -i 's/_/-/g' image.info
    for IMAGE in $(cat image.info);do
        docker image save ${IMAGE} -o $(echo ${IMAGE##*/} | awk -F: '{print $1}').tar
    done
    
    cat<<'EOF'>load_image.sh
#!/bin/bash
#
cd /tmp/image
for IMAGE in *.tar;do
    docker load -i ${IMAGE}
done
EOF
    
    for i in $(seq 1 $((${#NODE_NAMES[@]}-1)));do
        yellow_print ">>> ${NODE_NAMES[$i]} transfer k8s image and load k8s image"
        ssh ${NODE_NAMES[$i]} "mkdir -p /tmp/image"
        scp *.tar ${NODE_NAMES[$i]}:/tmp/image
        scp load_image.sh ${NODE_NAMES[$i]}:/tmp/image
        ssh ${NODE_NAMES[$i]} "cd /tmp/image;bash load_image.sh;cd /tmp;rm -rf /tmp/image"
    done;
    rm -rf /opt/work/image
}


kubeadm_master(){
    cd /opt/work
    #### init_kubeadm_config
    yellow_print ">>> kubeadm master init"
    kubeadm config print init-defaults > kubeadm-init.yaml
    sed -i "/advertiseAddress:/s/.*/  advertiseAddress: ${NODE_IPS[0]}/" kubeadm-init.yaml
    cat<<EOF>>kubeadm-init.yaml
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "ipvs"
EOF
    if [ ${#MASTER_NAMES[@]} -gt 1 ];then
        sed -i "/clusterName/acontrolPlaneEndpoint: \"${KUBE_APISEVER_VIP}:8443\"" kubeadm-init.yaml
    fi
    sed -i "/kubernetesVersion:/s/.*/kubernetesVersion: v${K8S_VER}/" kubeadm-init.yaml
    sed -i "/serviceSubnet:/s/.*/  serviceSubnet: 10.245.0.0\/16/" kubeadm-init.yaml
    sed -i "/serviceSubnet:/a  podSubnet: \"10.244.0.0\/16\"" kubeadm-init.yaml
    sed -ri "/podSubnet:/s/(.*)/  \1/" kubeadm-init.yaml


    kubeadm init --config kubeadm-init.yaml | tee kubeadm.log
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    ### command auto completion
    source <(kubectl completion bash)
    echo "source <(kubectl completion bash)" >> ~/.bashrc
    source  ~/.bashrc
}

kubeadm_other_master(){
    cd /opt/work
    JOIN_CONTROL_PLANE=$(grep -B 2 "\-\-control-plane" kubeadm.log  | tr '\' ' ' | tr "\n" " ")
    for i in $(seq 1 $((${#MASTER_NAMES[@]}-1)));do
        yellow_print ">>> ${MASTER_NAMES[$i]} join control plane"
        #### copy master ca to other master
        ssh ${MASTER_NAMES[$i]} "mkdir -p /etc/kubernetes/pki/etcd"
        scp /etc/kubernetes/pki/ca.* ${NODE_NAMES[$i]}:/etc/kubernetes/pki/
        scp /etc/kubernetes/pki/sa.* ${NODE_NAMES[$i]}:/etc/kubernetes/pki/
        scp /etc/kubernetes/pki/front-proxy-ca.* ${NODE_NAMES[$i]}:/etc/kubernetes/pki/
        scp /etc/kubernetes/pki/etcd/ca.* ${NODE_NAMES[$i]}:/etc/kubernetes/pki/etcd/
        scp /etc/kubernetes/admin.conf ${NODE_NAMES[$i]}:/etc/kubernetes/
        #### join master control plane
        ssh ${MASTER_NAMES[$i]} "${JOIN_CONTROL_PLANE}" 
        ssh ${MASTER_NAMES[$i]} "mkdir -p $HOME/.kube" 
        ssh ${MASTER_NAMES[$i]} "/bin/cp /etc/kubernetes/admin.conf $HOME/.kube/config" 
        ssh ${MASTER_NAMES[$i]} "chown $(id -u):$(id -g) $HOME/.kube/config" 

        ### command auto completion
        source <(kubectl completion bash)
        echo "source <(kubectl completion bash)" >> ~/.bashrc
        source  ~/.bashrc
    done;
}

kubeadm_work_join(){
    cd /opt/work
    if [ ${#MASTER_NAMES[@]} -eq 1 ];then
        JOIN_WORK_PLANE=$( grep -A 1 "kubeadm join" kubeadm.log  | tr '\' ' ' | tr "\n" " ")
    else
        JOIN_WORK_PLANE=$(grep -B 2 "\-\-control-plane" kubeadm.log | head -2  | tr '\' ' ' | tr "\n" " ")
    fi
    if [ WORK_NAMES ];then
        for i in $(seq 0 $((${#WORK_NAMES[@]}-1)));do
            yellow_print ">>> ${WORK_NAMES[$i]} join work plane"
            #### join work plane
            ssh ${WORK_NAMES[$i]} "${JOIN_WORK_PLANE}" 

            ### command auto completion
            source <(kubectl completion bash)
            echo "source <(kubectl completion bash)" >> ~/.bashrc
            source  ~/.bashrc
        done;
    fi
}

k8s_coredns_config(){
    cd /opt/work
    # default master mark taints , so core-dns is not schedule to master
    # add toleration to coredns
    # if [ $((${#NODE_NAMES[@]})) -eq 3 ];then
    #    yellow_print ">>> ${MASTER_NAMES} add toleration to coredns"
    #    kubectl patch deploy coredns -p '{"spec": {"template": {"spec": {"tolerations": [{"effect": "NoSchedule", "key": "node.kubernetes.io/not-ready"}, {"effect": "NoSchedule", "key": "node-role.kubernetes.io/master"}]}}}}' -n kube-system
    #fi
    yellow_print ">>> ${MASTER_NAMES} add toleration to coredns"
    if [ ${#NODE_NAMES[@]} -eq ${#MASTER_NAMES[@]} ];then
        kubectl patch deploy coredns -p '{"spec": {"template": {"spec": {"tolerations": [{"effect": "NoSchedule", "key": "node.kubernetes.io/not-ready"}, {"effect": "NoSchedule", "key": "node-role.kubernetes.io/master"}]}}}}' -n kube-system
    fi
}

install_flannel(){
    cd /opt/work
    # network addons
    yellow_print ">>> ${MASTER_NAMES} install flannel addons"
    mkdir flannel && cd flannel
    wget  https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
    kubectl apply -f kube-flannel.yml
}


install_calico(){
    cd /opt/work
    ## 简单介绍calico网络插件
    yellow_print ">>> ${MASTER_NAMES} install calico addons"
        wget https://docs.projectcalico.org/master/manifests/calico.yaml
    sed -i "/IPV4POOL_CIDR/{n;s@value:.*@value: \"$CLUSTER_CIDR\"@;}"  calico.yaml
        sed -i '/image/s/calico/quay.azk8s.cn\/calico/' calico.yaml
    kubectl apply -f calico.yaml
    ##  此处需要修改calico.yaml，该文件里面指定了pod使用的网络为 "192.168.0.0/16” ，要保证 kubeadm-init.yaml  和 calico.yaml 中的配置相同。本文中kubeadm-init.yaml 中配置了 podSubnet: "10.244.0.0/16”，因此需要修改calico.yaml。
}


install_weave(){
    cd /opt/work
        mkdir /opt/work/weave -p && cd /opt/work/weave
    yellow_print ">>> ${MASTER_NAMES} install weave addons"
        wget https://cloud.weave.works/k8s/scope.yaml?k8s-version=${K8S_VER} -O scopy.yaml
    kubectl apply  -f .
}

install_ingress-nginx(){
    cd /opt/work
        mkdir /opt/work/ingress-nginx -p && cd /opt/work/ingress-nginx 
    # daemonset install ingress-nginx to k8s-master, hostnetwork type
    yellow_print ">>> ${MASTER_NAMES} install ingress-nginx addons"
        wget https://raw.githubusercontent.com/skyisfuck/shell/master/k8s/ingress-nginx.yaml
    kubectl apply  -f .
}

install_metrics_server(){
    # resouces addons
    yellow_print ">>> ${MASTER_NAMES} install metrics server addons"
    cd /opt/work
    mkdir /opt/work/metrics-server -p && cd /opt/work/metrics-server
    METRICS_DEPLOY_FILE="aggregated-metrics-reader.yaml auth-delegator.yaml auth-reader.yaml metrics-apiservice.yaml metrics-server-deployment.yaml metrics-server-service.yaml resource-reader.yaml"
    for FILE_NAME in ${METRICS_DEPLOY_FILE};do
        wget https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/${FILE_NAME}
    done;
    cp metrics-server-deployment.yaml{,.bak}
    sed -i '/k8s.gcr.io/s@k8s.gcr.io@gcr.azk8s.cn/google_containers@' metrics-server-deployment.yaml
    sed -i '/imagePullPolicy/s@Always@IfNotPresent@' metrics-server-deployment.yaml
    sed -i '/imagePullPolicy/a%        command:' metrics-server-deployment.yaml
    sed -i '/%.*command/a%        - --kubelet-preferred-address-types=InternalIP,Hostname,InternalDNS,ExternalDNS,ExternalIP' metrics-server-deployment.yaml
    sed -i '/%.*command/a%        - --metric-resolution=30s' metrics-server-deployment.yaml
    sed -i '/%.*command/a%        - --kubelet-insecure-tls' metrics-server-deployment.yaml
    sed -i '/%.*command/a%        - /metrics-server' metrics-server-deployment.yaml
    sed -i 's/^%//'  metrics-server-deployment.yaml
    
    if [ ${#NODE_NAMES[@]} -eq ${#MASTER_NAMES[@]} ];then
        if grep -q "tolerations:" metrics-server-deployment.yaml;then
            if grep -q "key.*CriticalAddonsOnly" metrics-server-deployment.yaml;then
                :
            else
                sed -i '/tolerations:/a%          operator: "Exists"' metrics-server-deployment.yaml
                sed -i '/tolerations:/a%        - key: "CriticalAddonsOnly"' metrics-server-deployment.yaml
                sed -i 's/^%//'  metrics-server-deployment.yaml
            fi
        else
            cat<<EOF>>./metrics-server-deployment.yaml
      tolerations:
        - key: "CriticalAddonsOnly"
          operator: "Exists"
EOF
        fi
    fi
        
    # default master mark taints , so metrics-server is not schedule to master
    # add toleration to metrics-server
    if [ ${#NODE_NAMES[@]} -eq ${#MASTER_NAMES[@]} ];then
        sed -i '/tolerations:/a%          effect: "NoSchedule"' metrics-server-deployment.yaml
        sed -i '/tolerations:/a%          operator: "Equal"' metrics-server-deployment.yaml
        sed -i '/tolerations:/a%        - key: "node-role.kubernetes.io/master"' metrics-server-deployment.yaml
        sed -i 's/^%//'  metrics-server-deployment.yaml
    fi

    kubectl apply -f .
}


install_helm(){
    cd /opt/work
        mkdir /opt/work/helm -p && cd /opt/work/helm
    yellow_print ">>> ${MASTER_NAMES} install helm"
    curl -s https://raw.githubusercontent.com/skyisfuck/shell/master/k8s/install_helm.sh | bash
}

install_dashboard(){
    # dashboard addons
    yellow_print ">>> ${MASTER_NAMES} install dashboard addons"
    cd /opt/work
    mkdir /opt/work/dashboard -p && cd /opt/work/dashboard
    wget https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
    sed -i '/k8s.gcr.io/s@k8s.gcr.io@gcr.azk8s.cn/google_containers@' kubernetes-dashboard.yaml
    sed -i '/targetPort/a\ \ type: NodePort'  kubernetes-dashboard.yaml
    if [ ${#NODE_NAMES[@]} -eq ${#MASTER_NAMES[@]} ];then
        sed -i '/tolerations:/a%        effect: "NoSchedule"' kubernetes-dashboard.yaml
        sed -i '/tolerations:/a%        operator: "Equal"' kubernetes-dashboard.yaml
        sed -i '/tolerations:/a%      - key: "node-role.kubernetes.io/master"' kubernetes-dashboard.yaml
        sed -i 's/^%//'  kubernetes-dashboard.yaml
    fi
    kubectl apply -f .
   
    # create dashboard serviceaccount and bind to cluster role
    kubectl create sa dashboard-admin -n kube-system
    kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin

    DASHBOARD_TOKEN=$(kubectl get secrets -n kube-system $(kubectl -n kube-system get secret | awk '/dashboard-admin/{print $1}')   -o go-template --template={{.data.token}} | base64 -d)
    DASHBOARD_PORT=$(kubectl get svc kubernetes-dashboard -n kube-system -ogo-template --template='{{range .spec.ports}}{{.nodePort}}{{end}}')
    

    blue_print "dashboard url = https://${MASTER_IPS}:${DASHBOARD_PORT}"
    blue_print "dashboard token = ${DASHBOARD_TOKEN}"
}



install(){
    mkdir /opt/work -p && cd /opt/work
    grubby --default-kernel | grep "/boot/vmlinuz-5" || {
        init_env_config
    }
    install_docker_ipvs
    install_k8s
    if [ ${#MASTER_NAMES[@]} -gt 1 ];then
        install_haproxy_keepalived
    fi;
    download_k8s_image
    export K8S_VER=$(kubeadm config images list   2>/dev/null |  grep "apiserver"  | sed  's/.*:v//')
    kubeadm_master
    if [ ${#MASTER_NAMES[@]} -gt 1 ];then
        kubeadm_other_master
    fi;
    kubeadm_work_join
    k8s_coredns_config
    if [ "${NET_PLUGIN}" == "calico" ];then
        install_calico
    elif [ "${NET_PLUGIN}" == "flannel" ];then
        install_flannel
    else
        install_calico
    fi;
    install_weave
    install_ingress-nginx
    install_metrics_server
    install_helm
    install_dashboard
}

install
