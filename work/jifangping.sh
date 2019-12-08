yum install rrdtool rrdtool-perl rrdtool-devel  openssl-devel fping perl-core  libffi-devel git

cd /root

wget https://www.openssl.org/source/openssl-1.1.0k.tar.gz
./config shared zlib --prefix=/usr/local/openssl-1.1.0k
 
wget https://www.python.org/ftp/python/3.7.4/Python-3.7.4.tar.xz
tar xf Python-3.7.4.tar.xz
cat >> /root/Python-3.7.4/Modules/Setup.dist <<"EOF"
_socket socketmodule.c
 
SSL=/usr/local/openssl
_ssl _ssl.c \
-DUSE_SSL -I$(SSL)/include -I$(SSL)/include/openssl \
-L$(SSL)/lib -lssl -lcrypto
EOF
./configure --enable-optimizations  --prefix=/usr/local/python3.7 
 
 
 
wget https://oss.oetiker.ch/smokeping/pub/smokeping-2.7.3.tar.gz
./configure --prefix=/usr/local/smokeping
  
  
wget https://github.com/prometheus/prometheus/releases/download/v2.11.2/prometheus-2.11.2.linux-amd64.tar.gz
[root@fping system]# cat prometheus.service 
[Unit]
Description=Prometheus Server
Documentation=https://prometheus.io/docs/introduction/overview/
After=network-online.target

[Service]
User=prometheus
Restart=on-failure

#Change this line if you download the 
#Prometheus on different path user
ExecStart=/home/prometheus/prometheus/prometheus \
  --config.file=/home/prometheus/prometheus/prometheus.yml \
  --storage.tsdb.path=/home/prometheus/prometheus/data

[Install]
WantedBy=multi-user.target

wget https://github.com/prometheus/node_exporter/releases/download/v0.18.1/node_exporter-0.18.1.linux-amd64.tar.gz
[root@fping system]# cat node_exporter.service 
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
ExecStart=/home/prometheus/node_exporter/node_exporter

[Install]
WantedBy=default.target

wget https://github.com/prometheus/pushgateway/releases/download/v0.9.1/pushgateway-0.9.1.linux-amd64.tar.gz
[root@fping system]# cat pushgateway.service 
[Unit]
Description=Push Gateway
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
ExecStart=/home/prometheus/pushgateway/pushgateway

[Install]
WantedBy=default.target
wget https://github.com/prometheus/alertmanager/releases/download/v0.18.0/alertmanager-0.18.0.linux-amd64.tar.gz
[root@fping system]# cat alertmanager.service 
[Unit]
Description=alert manager
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
ExecStart=/home/prometheus/alertmanager/alertmanager \
           --config.file="/home/prometheus/alertmanager/alertmanager.yml"
Restart=on-failure

[Install]
WantedBy=default.target
 
 
 
wget https://mirrors.tuna.tsinghua.edu.cn/grafana/yum/rpm/grafana-6.3.3-1.x86_64.rpm
 
 
 
 cd /tmp
git clone https://github.com/skyisfuck/idc_ping_monitor.git
 
smokeping_home_dir=/usr/local/smokeping
cd $smokeping_home_dir/etc
cp -rf /tmp/idc_ping_monitor/smokeping/* ./

mkdir -p $smokeping_home_dir/cache
mkdir -p $smokeping_home_dir/data
mkdir -p $smokeping_home_dir/var
chmod -R 0755 $smokeping_home_dir
chmod 600 $smokeping_home_dir/etc/smokeping_secrets.dist



#### centos需要改，ubuntu不用,因为centos smokeping 没有-4选项，是直接4选项，ubuntu是-4选项，标识ipv4
安装smokeping后，注释 /usr/local/smokeping/lib/Smokeping/probes/FPing.pm 202行左右一下内容
    202 #               protocol => {
    203 #                       _re => '(4|6)',
    204 #                       _example => '4',
    205 #                       _default => '4',
    206 #                       _doc => "Choose if the ping should use IPv4 or IPv6.",
    207 #
    208 #               },
如果觉的smokeping取的数据有问题，可使用/usr/local/smokeping/bin/smokeping --debug 查看详细信息
#####


还要修改作者的ping_monitor.json，把里面的job修改成改成exports_job，要对应prometheus中的exports_jobs，不然grafana上没有数据


$smokeping_home_dir/bin/smokeping
