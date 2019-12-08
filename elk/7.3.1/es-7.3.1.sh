#!/bin/bash
#
# ES CLUSTER ALL IP
ES_IPS=(192.168.100.10 192.168.100.11 192.168.100.12)
# ES CLUSTER NAME
ES_NAMES=(es1 es2 es3)
# ES CLUSTER PASSWORD
ES_PASS=(redhat redhat redhat)

yellow_print(){
    echo -e "\033[33m$1\033[0m"
}

blue_print(){
    echo -e "\033[34m$1\033[0m"
}


set -ex

## es 7版本 自带了openjdk，所以不用安装openjdk，es 6需要自己安装openjdk

init_env_config(){
    cd /opt/work
    # add host config
    for i in $(seq 0 $((${#ES_NAMES[@]}-1)));do
        yellow_print ">>> ${ES_NAMES[$i]}  add host config"
        echo "${ES_IPS[$i]} ${ES_NAMES[$i]}">>/etc/hosts;
    done

    # distribute ssh master key
    which sshpass &>/dev/null || yum install sshpass -y
    ssh-keygen -t rsa -P '' -f /root/.ssh/id_rsa
    for i in $(seq 0 $((${#ES_NAMES[@]}-1)));do
        yellow_print ">>> ${ES_NAMES[$i]} distribute ssh master key"
        sshpass -p "${ES_PASS[$i]}" scp -o StrictHostKeyChecking=no /etc/hosts root@${ES_IPS[$i]}:/etc/hosts
        sshpass -p "${ES_PASS[$i]}" ssh-copy-id -o StrictHostKeyChecking=no root@${ES_NAMES[$i]}
        ssh ${ES_NAMES[$i]} hostnamectl set-hostname ${ES_NAMES[$i]}
    done;
  
    # centos7_init_env_config
    for i in $(seq 0 $((${#ES_NAMES[@]}-1)));do
        yellow_print ">>> ${ES_NAMES[$i]} centos7_init_env_config"
        ssh ${ES_NAMES[$i]} "wget https://raw.githubusercontent.com/skyisfuck/shell/master/init/centos7_init.sh; bash centos7_init.sh ${ES_NAMES[$i]}; rm -f centos7_init.sh" 
    done;
}

install_es(){
    cd /opt/work
    wget https://mirrors.tuna.tsinghua.edu.cn/elasticstack/7.x/yum/7.3.1/elasticsearch-7.3.1-x86_64.rpm
    for i in $(seq 0 $((${#ES_NAMES[@]}-1)));do
        yellow_print ">>> ${ES_NAMES[$i]} install elasticsearch"
        scp  elasticsearch-7.3.1-x86_64.rpm root@${ES_IPS[$i]}:/tmp/elasticsearch-7.3.1-x86_64.rpm
        ssh ${ES_NAMES[$i]} "rpm -ivh /tmp/elasticsearch-7.3.1-x86_64.rpm;rm -f /tmp/elasticsearch-7.3.1-x86_64.rpm"
    done;
}

configure_es(){
    cd /opt/work
    
    for i in $(seq 0 $((${#ES_NAMES[@]}-1)));do
        yellow_print ">>> ${ES_NAMES[$i]} configure elasticsearch"
        cat<<EOF>elasticsearch_${i}.yml
cluster.name: elk-cluster
node.name: ${ES_NAMES[${i}]}
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: ${ES_IPS[${i}]}
http.port: 9200
discovery.seed_hosts: ["${ES_IPS[0]}", "${ES_IPS[1]}", "${ES_IPS[2]}"]
cluster.initial_master_nodes: ["${ES_IPS[0]}", "${ES_IPS[1]}", "${ES_IPS[2]}"]
http.cors.enabled: true                                     # elasticsearch中启用CORS
http.cors.allow-origin: "*"                                 # 允许访问的IP地址段，* 为所有IP都可以访问
EOF
        scp elasticsearch_${i}.yml root@${ES_NAMES[$i]}:/etc/elasticsearch/elasticsearch.yml
        ssh ${ES_NAMES[$i]} "systemctl enable --now elasticsearch"
    done
    
}

install_head(){
    cd /opt/work
    yellow_print ">>> ${ES_NAMES[$i]} install elasticsearch-head addons"
    yum install git npm -y;
    cd /usr/local;
    npm config set registry https://registry.npm.taobao.org
    git clone https://github.com/mobz/elasticsearch-head.git;
    cd /usr/local/elasticsearch-head && npm install;
    
    cat<<EOF>/etc/systemd/system/elasticsearch-head.service
[Unit]
Description=Elasticsearch-head
After=network.target syslog.target

[Service]
Type=simple
WorkingDirectory=/usr/local/elasticsearch-head
ExecStart=/usr/bin/npm run start
Restart=always
StandardOutput=syslog
StandardError=syslog

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now elasticsearch-head
}


install(){
    mkdir /opt/work -p && cd /opt/work
    init_env_config
    install_es
    configure_es
    install_head
}
install
