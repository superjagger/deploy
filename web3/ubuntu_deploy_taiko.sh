#!/bin/bash

# 部署taiko验证者节点，命令行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/ubuntu_deploy_taiko.sh | bash -s -- "私钥" "Ethereum Sepolia HTTP RPC连接" "Ethereum Sepolia WS RPC连接"


private_key=$1
http_rpc=$2
ws_rpc=$3

if [ -z "$private_key" ] || [ -z "$http_rpc" ] || [ -z "$ws_rpc" ]; then
    echo "缺少参数"
    exit 1
fi
# 安装基础组件
apt-get install git

# 安装docker
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/ubuntu_deploy_docker.sh | bash

taiko_dir=$HOME/taiko_dir
mkdir -p $taiko_dir
cd $taiko_dir
git clone https://github.com/taikoxyz/simple-taiko-node.git
cd simple-taiko-node
cp .env.sample .env

sed -i -e "s/^L1_ENDPOINT_HTTP=.*/L1_ENDPOINT_HTTP=$http_rpc/; s/^L1_ENDPOINT_WS=.*/L1_ENDPOINT_WS=$ws_rpc/; s/^ENABLE_PROVER=false.*/ENABLE_PROVER=true/; s/^L1_PROVER_PRIVATE_KEY=.*/L1_PROVER_PRIVATE_KEY=$private_key/" .env

docker compose up -d
