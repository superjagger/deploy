#!/bin/bash

# 关闭防火墙

service firewalld stop
service iptables stop
ufw disable
