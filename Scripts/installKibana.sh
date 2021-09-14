#!/bin/bash

ip=`wget -qO- ipecho.net/plain`

##############################
#   Install NGINX    #
##############################

sudo apt install nginx -y
sudo ufw allow 'Nginx HTTP'
sudo ufw enable

sudo touch /etc/nginx/sites-available/$ip

sudo bash -c "echo "server {
    listen 80;

    server_name your_domain;

    auth_basic "Restricted Access";
    auth_basic_user_file /etc/nginx/htpasswd.users;

    location / {
        proxy_pass http://localhost:5601;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}" >> /etc/nginx/sites-available/$ip"

sudo nginx -t

sudo systemctl reload nginx

sudo ufw allow 'Nginx Full'


##############################
#   Install JAVA    #
##############################

sudo apt-get install openjdk-11-jdk wget apt-transport-https curl gnupg2 -y

echo "Check Java Version"
java -version

##############################
#   Install ElasticSearch    #
##############################

sudo wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list


sudo apt-get update -y
sudo apt-get install elasticsearch -y

sudo systemctl start elasticsearch
sudo systemctl enable elasticsearch

ss -antpl | grep 9200


curl -X GET http://localhost:9200


########################################
#   Install and Configure Logstash     #
########################################

sudo apt-get install logstash -y

#nano /etc/logstash/conf.d/logstash.conf


sudo bash -c "echo #Specify listening port for incoming logs from the beats

input {
  beats {
    port => 5044
  }
}

# Used to parse syslog messages and send it to Elasticsearch for storing

filter {
  if [type] == "syslog" {
     grok {
        match => { "message" => "%{SYSLOGLINE}" }
  }
     date {
        match => [ "timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
     }
  }
}

# Specify an Elastisearch instance

output {
  elasticsearch {
    hosts => ["localhost:9200"]
    index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"
  }
} >> /etc/logstash/conf.d/logstash.conf"


sudo systemctl start logstash
sudo systemctl enable logstash


########################################
#   Install and Configure Logstash     #
########################################

sudo apt-get install kibana -y

ip=`wget -qO- ipecho.net/plain`

sudo bash -c "echo server.host: localhost
elasticsearch.hosts: ["http://localhost:9200"] >> /etc/kibana/kibana.yml"

sudo systemctl start kibana
sudo systemctl enable kibana


########################################
#   Install and Configure Filebeat     #
########################################

sudo apt-get install filebeat -y

sudo touch /etc/filebeat/filebeat.yml


sudo bash -c "echo "
...
#output.elasticsearch:
  # Array of hosts to connect to.
  #hosts: ["localhost:9200"]
...
" >>  /etc/filebeat/filebeat.yml"

sudo filebeat modules enable system

sudo filebeat modules list

sudo filebeat setup --pipelines --modules system

sudo filebeat setup --index-management -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=["localhost:9200"]'

sudo filebeat setup -E output.logstash.enabled=false -E output.elasticsearch.hosts=['localhost:9200'] -E setup.kibana.host=localhost:5601

sudo systemctl start filebeat
sudo systemctl enable filebeat

curl -XGET 'http://localhost:9200/filebeat-*/_search?pretty'
