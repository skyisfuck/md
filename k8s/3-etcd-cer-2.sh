#!/bin/bash
#

ETCD_SSL=/usr/local/etcd/ssl
# 注意58行得etcd ip


which cfssl &>/dev/null || {
    wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -O cfssl
    wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64  -O cfssljson
    wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 -O cfssl-certinfo
    chmod +x cfssl*
    mv cfssl* /usr/local/bin
}


cat<<EOF>$ETCD_SSL/ca-config.json
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "www": {
         "expiry": "87600h",
         "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ]
      }
    }
  }
}
EOF

cat<<EOF>$ETCD_SSL/ca-csr.json
{
    "CN": "etcd CA",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Beijing",
            "ST": "Beijing"
        }
    ]
}
EOF
cat<<EOF>$ETCD_SSL/server-csr.json
{
    "CN": "etcd",
    "hosts": [
    "192.168.4.180"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Beijing",
            "ST": "Beijing"
        }
    ]
}
EOF
cd $ETCD_SSL
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=www server-csr.json | cfssljson -bare server
cd ~
# ca-key.pem  ca.pem  server-key.pem  server.pem
ls $ETCD_SSL/*.pem
