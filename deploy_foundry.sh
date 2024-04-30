#!/bin/bash

source $HOME/.bash_profile

# foundry 安装脚本，执行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_foundry.sh | bash

if which forge > /dev/null 2>&1; then
    echo "foundry 已经安装"
else
    echo "foundry 未安装"
    curl -L https://foundry.paradigm.xyz | bash
    echo ' export PATH="$PATH:/root/.foundry/bin"' >>$HOME/.bash_profile
    source $HOME/.bash_profile
    foundryup
fi
