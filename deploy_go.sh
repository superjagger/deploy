#!/bin/bash

if ! command -v go &>/dev/null; then
    echo "Go 未安装"
    wget https://golang.org/dl/go1.21.4.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.21.4.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >>$HOME/.bash_profile
    source $HOME/.bash_profile
    go version
else
    echo "Go 已经安装"
fi
