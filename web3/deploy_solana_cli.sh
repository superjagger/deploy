#!/bin/bash

source $HOME/.bash_profile

# solana cli 安装脚本，执行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/deploy_solana_cli.sh | bash

if which solana > /dev/null 2>&1; then
    echo "solana cli 已经安装"
else
    echo "solana cli 未安装"
    
    # 安装 rust
    curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_rust.sh | bash
    
    # 安装 Node.js
    curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_node.sh | bash
    
    # 部署Solana CLI 
    sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
    
    # 写入环境变量，永久生效
    echo 'export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"' >>$HOME/.profile
    echo 'export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"' >>$HOME/.bash_profile
    source $HOME/.bash_profile
fi
