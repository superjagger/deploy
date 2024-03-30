#!/bin/bash

source $HOME/.bash_profile

# solana cli 安装脚本，执行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/debian_solana_cli.sh | bash

if ! command -v solana &>/dev/null; then
    echo "solana cli 未安装"
    
    # 部署Solana CLI 
    sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
    
    # 写入环境变量，永久生效
    echo 'export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"' >>$HOME/.profile
    echo 'export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"' >>$HOME/.bash_profile
    source $HOME/.bash_profile

else
    echo "solana cli 已经安装"
fi
