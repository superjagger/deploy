#!/bin/bash

# ore 挖矿脚本: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/debian_mining_ore.sh | bash

# 安装ore挖矿程序
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/debian_deploy_ore.sh | bash

# 安装 expect
apt-get install expect

# 下载助记词导入脚本
curl -O https://raw.githubusercontent.com/superjagger/deploy/main/web3/recover_solana_keygen.exp

# 挖矿钱包助记词
phrase=$1

if [ -z "$phrase" ]; then
    echo "缺少参数: phrase"
    exit 1
fi


# 导入 solana 钱包作为挖矿钱包
expect recover_solana_keygen.exp "$phrase" "prompt://?full-path=m/44'/501'/0'/0'"

# 后台挖矿
nohup ore --rpc https://api.mainnet-beta.solana.com --keypair ~/.config/solana/id.json --priority-fee 1 mine --threads 4 >output.log 2>&1 &
