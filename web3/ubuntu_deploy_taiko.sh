#!/bin/bash

# 部署taiko验证者节点，命令行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/ubuntu_deploy_taiko.sh | bash -s -- "钱包地址" "私钥" "Ethereum Holskey HTTP RPC连接" "Ethereum Holskey WS RPC连接" "Beacon Holskey RPC连接" "prover_endpoints 地址"
# 可以用下面的公共rpc地址
# http_rpc=https://ethereum-holesky-rpc.publicnode.com
# ws_rpc=wss://ethereum-holesky-rpc.publicnode.com
# beacon_rpc=https://ethereum-holesky-beacon-api.publicnode.com
# prover_endpoints=http://kenz-prover.hekla.kzvn.xyz:9876

echo "开始部署taiko验证者节点"
address=$1
private_key=$2
http_rpc=$3
ws_rpc=$4
beacon_rpc=$5
prover_endpoints=$5

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
sed -i "s|PROVER_ENDPOINTS=.*|PROVER_ENDPOINTS=${prover_endpoints}|" .env

echo "停止 Taiko 容器"
docker compose --profile l2_execution_engine down
docker stop simple-taiko-node-taiko_client_proposer-1 && docker rm simple-taiko-node-taiko_client_proposer-1
echo "删除原有数据"
docker volume rm simple-taiko-node_grafana_data simple-taiko-node_l2_execution_engine_data simple-taiko-node_prometheus_data simple-taiko-node_zkevm_chain_prover_rpcd_data

echo "运行 Taiko 节点容器"
docker compose --profile l2_execution_engine up -d

echo "运行 Taiko proposer 节点"
docker compose up taiko_client_proposer -d

echo "结束部署taiko验证者节点"
