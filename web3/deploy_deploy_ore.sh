#!/bin/bash

# ORE 挖矿脚本，执行命令: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/deploy_deploy_ore.sh | bash

# 部署 solana cli
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/deploy_solana_cli.sh | bash

source $HOME/.bash_profile

# 安装 ore 挖矿程序
cargo install ore-cli

