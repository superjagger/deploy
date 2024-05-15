#!/bin/bash
source $HOME/.bash_profile

# 系统：Debian
# go 安装不同版本脚本，执行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_go_version.sh | bash -s -- [版本号]

go_version=$1
if [ -z "$go_version" ]; then
    echo "缺少变量"
    exit 1
fi
go_dir=/usr/local/go_${go_version}

export PATH=$PATH:${go_dir}/go/bin

if which go > /dev/null 2>&1; then
    echo "Go 已经安装"
else
    echo "Go 未安装"
    wget https://golang.org/dl/go${go_version}.linux-amd64.tar.gz >deploy_go.log 2>&1
    mkdir -p ${go_dir}
    tar -C ${go_dir} -xzf go${go_version}.linux-amd64.tar.gz
    export PATH=$PATH:${go_dir}/go/bin
    go version
    rm go${go_version}.linux-amd64.tar.gz
fi
