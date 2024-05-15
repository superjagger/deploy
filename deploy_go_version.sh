#!/bin/bash
# 系统：Debian
# go 安装不同版本脚本，执行: 
# go_version=1.20.14 # 设定go版本号
# curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_go_version.sh | bash -s -- $go_version
# go_dir=/usr/local/go_${go_version}
# export PATH=$PATH:${go_dir}/go/bin # 将go的目录临时添加到环境变量中，只保存当前命令行窗口

go_version=$1
if [ -z "$go_version" ]; then
    echo "缺少变量：go 版本号"
    exit 1
fi
go_dir=/usr/local/go_${go_version}

export PATH=$PATH:${go_dir}/go/bin:$HOME/go/bin

if which go > /dev/null 2>&1; then
    echo "Go ${go_version}已经安装"
else
    echo "Go ${go_version}未安装"
    wget https://golang.org/dl/go${go_version}.linux-amd64.tar.gz >deploy_go.log 2>&1
    mkdir -p ${go_dir}
    go_tar=go${go_version}.linux-amd64.tar.gz
    # 检查文件是否存在
    if [ ! -f "$go_tar" ]; then
        echo "版本 $go_tar 不存在."
        exit 1
    fi
    tar -C ${go_dir} -xzf go${go_version}.linux-amd64.tar.gz
    export PATH=$PATH:${go_dir}/go/bin:$HOME/go/bin
    go version
    rm go${go_version}.linux-amd64.tar.gz
fi
