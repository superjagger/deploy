#!/bin/bash

# 部署taiko验证者节点，命令行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/ubuntu_deploy_taiko.sh | bash -s -- "钱包地址" "私钥" "Ethereum Holskey HTTP RPC连接" "Ethereum Holskey WS RPC连接" "Beacon Holskey RPC连接"

echo "开始部署taiko验证者节点"
address=$1
private_key=$2
http_rpc=$3
ws_rpc=$4
beacon_rpc=$5

echo "private_key=${private_key}"
echo "http_rpc=${http_rpc}"
echo "ws_rpc=${ws_rpc}"
echo "beacon_rpc=${beacon_rpc}"

if [ -z "$private_key" ] || [ -z "$http_rpc" ] || [ -z "$ws_rpc" ]; then
    echo "缺少参数"
    exit 1
fi
# 安装基础组件
apt-get install git

# 安装docker
while true  
do  
    curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/ubuntu_deploy_docker.sh | bash
    if which docker > /dev/null 2>&1; then
        break
    fi
done

taiko_dir=$HOME/taiko_dir
mkdir -p $taiko_dir
cd $taiko_dir
rm -rf simple-taiko-node
git clone https://github.com/taikoxyz/simple-taiko-node.git
cd simple-taiko-node
cp .env.sample .env

sed -i -e "s#^L1_ENDPOINT_HTTP=.*#L1_ENDPOINT_HTTP=$http_rpc#; s#^L1_ENDPOINT_WS=.*#L1_ENDPOINT_WS=$ws_rpc#; s#^ENABLE_PROVER=false.*#ENABLE_PROVER=true#; s#^L1_PROVER_PRIVATE_KEY=.*#L1_PROVER_PRIVATE_KEY=$private_key#" .env
sed -i "s|L1_BEACON_HTTP=.*|L1_BEACON_HTTP=${beacon_rpc}|" .env
# 钱包地址
sed -i "s|L2_SUGGESTED_FEE_RECIPIENT=.*|L2_SUGGESTED_FEE_RECIPIENT=${address}|" .env

sed -i "s|ENABLE_PROPOSER=.*|ENABLE_PROPOSER=true|" .env
sed -i "s|DISABLE_P2P_SYNC=.*|DISABLE_P2P_SYNC=false|" .env

echo "停止容器"
docker compose down
echo "启动容器"
docker compose up -d
echo "结束部署taiko验证者节点"
