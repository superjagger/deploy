#!/bin/bash
source $HOME/.bash_profile

# 系统：Debian
# go 安装脚本，执行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_go.sh | bash

if which go > /dev/null 2>&1; then
    echo "Go 已经安装"
else
    echo "Go 未安装"
    wget https://golang.org/dl/go1.21.4.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.21.4.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >>$HOME/.bash_profile
    source $HOME/.bash_profile
    go version
    
    rm go1.21.4.linux-amd64.tar.gz
fi
