#!/bin/bash

# 关闭防火墙 
# curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/stop_firewall.sh | bash

service firewalld stop
service iptables stop
ufw disable
