#!/bin/bash

# ore 挖矿脚本: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/debian_mining_ore.sh | bash -s -- "你的助记词"

# 挖矿钱包助记词
phrase=$1

if [ -z "$phrase" ]; then
    echo "缺少参数: phrase"
    exit 1
fi


# 安装 expect
apt-get install expect

# 安装ore挖矿程序
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/debian_deploy_ore.sh | bash

source $HOME/.bash_profile

# 下载助记词导入脚本
curl -O https://raw.githubusercontent.com/superjagger/deploy/main/web3/recover_solana_keygen.exp

# 导入 solana 钱包作为挖矿钱包
expect recover_solana_keygen.exp "$phrase" "prompt://?full-path=m/44'/501'/0'/0'"
rm -rf recover_solana_keygen.exp

# 钱包地址
echo "钱包地址: $(solana address)"

# 后台挖矿，写了个死循环一直尝试挖矿
nohup bash -c 'while true; do ore --rpc https://api.mainnet-beta.solana.com --keypair ~/.config/solana/id.json --priority-fee 1 mine --threads 4; done' > mining_ore_output.log 2>&1 &
