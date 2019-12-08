#!/bin/bash
#


cp /etc/logstash/logstash.yml{,.bak}

cat<<EOF>/etc/logstash/logstash.yml
input {
    redis {
        host => "192.168.100.13"
        port => 6379
        password => "123456"
        db => "0"
        data_type => "list"
        key => "filebeat"
    }
}

filter {
}

output {
  elasticsearch {
      hosts  => ["http://192.168.100.10:9200","http://192.168.100.11:9200","http://192.168.100.12:9200"]
      index  => "logstash-%{type}-%{+YYYY.MM.dd}"
  }
  stdout{codec => rubydebug }
}
EOF

cat<<EOF>/etc/systemd/system/logstash.service
[Unit]
Description=logstash

[Service]
Type=simple
#User=logstash
#Group=logstash
# Load env vars from /etc/default/ and /etc/sysconfig/ if they exist.
# Prefixing the path with '-' makes it try to load, but if the file doesn't
# exist, it continues onward.
#EnvironmentFile=-/etc/default/logstash
#EnvironmentFile=-/etc/sysconfig/logstash
#ExecStart=/usr/share/logstash/bin/logstash "--path.settings" "/etc/logstash"
ExecStart=/usr/share/logstash/bin/logstash -f /etc/logstash/logstash.yml -r
Restart=always
#WorkingDirectory=/
#Nice=19
#LimitNOFILE=16384

[Install]
WantedBy=multi-user.target
EOF
