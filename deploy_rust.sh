#!/bin/bash

source $HOME/.bash_profile

# rust 安装脚本，执行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_rust.sh | bash

if ! command -v rustc &>/dev/null; then
    echo "rust 未安装"

else
    echo "rust 已经安装"
fi
