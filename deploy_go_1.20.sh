#!/bin/bash
source $HOME/.bash_profile

# 系统：Debian
# go 1.20 版本安装脚本，执行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_go_1.20.sh | bash

if which go > /dev/null 2>&1; then
    echo "Go 已经安装"
else
    echo "Go 未安装"
    wget https://golang.org/dl/go1.20.14.linux-amd64.tar.gz >deploy_go.log 2>&1
    tar -C /usr/local -xzf go1.20.14.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >>$HOME/.bash_profile
    source $HOME/.bash_profile
    go version
    
    rm go1.20.14.linux-amd64.tar.gz
fi
