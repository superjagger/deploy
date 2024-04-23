#!/bin/bash

if [ ! -f "$HOME/.bash_profile" ]; then
    echo "$HOME/.bash_profile 文件不存在自动创建"
    touch $HOME/.bash_profile
fi

source $HOME/.bash_profile

# rust 安装脚本，执行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_rust.sh | bash

if which rustc > /dev/null 2>&1; then
    echo "rust 已经安装"
else
    echo "rust 未安装"
    # 安装 rust
    cd $HOME
    curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf > rustup.sh
    bash rustup.sh -y
    rm -rf rustup.sh
    # 写入环境变量，永久生效
    echo 'export PATH=$PATH:$HOME/.cargo/env' >>$HOME/.bash_profile
    source $HOME/.bash_profile
    
    # 查看安装后版本
    rustc --version
    cargo --version
fi
