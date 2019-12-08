#!/bin/bash
#
yum install gcc gcc-c++ make cmake -y
wget http://download.redis.io/releases/redis-5.0.5.tar.gz
tar xf redis-5.0.5.tar.gz
cd redis-5.0.5/deps
make lua hiredis jemalloc linenoise
cd ..
make 
cd src
make PREFIX=/usr/local/redis-5.0.5 install
cd ..
ln -s /usr/local/redis-5.0.5 /usr/local/redis
cp redis.conf /usr/local/redis/ 

cat <<'EOF'>/etc/profile.d/redis.sh
#!/bin/bash
#
export PATH=/usr/local/redis/bin:$PATH
EOF
. /etc/profile.d/redis.sh

cat<<'EOF'>/etc/sysctl.d/redis.conf
net.core.somaxconn = 2048
vm.overcommit_memory = 1
EOF
sysctl --system

echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled">>/etc/rc.local
chmod +x /etc/rc.local




cat<<'EOF'>/etc/systemd/system/redis-server.service
[Unit]
Description=Redis Server Manager
After=network.target
 
[Service]
Type=simple
User=root
PIDFile=/var/run/redis_6379.pid
ExecStart=/usr/local/redis/bin/redis-server /usr/local/redis/redis.conf
ExecStop=/usr/local/redis/bin/redis-cli shutdown
Restart=always
 
[Install]
WantedBy=multi-user.target
EOF

sed -i 's@^dir ./@dir /usr/local/redis@' /usr/local/redis/redis.conf
sed -i 's@^bind .*@bind 0\.0\.0\.0@' /usr/local/redis/redis.conf
read -p "please input password for redis > " PASS
until [ $PASS ];do
    read -p "please input password for redis > " PASS
done
sed -i "/# requirepass/arequirepass $PASS" /usr/local/redis/redis.conf


systemctl enable --now redis-server
sleep 3
systemctl status redis-server
