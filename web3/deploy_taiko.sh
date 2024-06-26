#!/bin/bash

# debian 系统
# 部署taiko验证者节点，命令行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/debian_deploy_taiko.sh | bash -s -- "钱包地址" "私钥" "Ethereum Holskey HTTP RPC连接" "Ethereum Holskey WS RPC连接" "Beacon Holskey RPC连接" "prover_endpoints 地址" "输入1是清空数据"
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
prover_endpoints=$6

if [ -z "$7" ]; then
    clear=0
else
    clear=$7
fi

if [ $clear -eq 1 ]; then
    echo "本次脚本会删除原有数据，如果不想删除及时退出脚本！"
    sleep 1
    echo "3"
    sleep 1
    echo "2"
    sleep 1
    echo "1"
fi

echo "address=${address}"
echo "private_key=${private_key}"
echo "http_rpc=${http_rpc}"
echo "ws_rpc=${ws_rpc}"
echo "beacon_rpc=${beacon_rpc}"
echo "prover_endpoints=${prover_endpoints}"

if [ -z "$ws_rpc" ]; then
    echo "缺少参数"
    exit 1
fi
# 安装基础组件
apt-get install git

# 安装docker
while true; do
    curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/debian_deploy_docker.sh | bash
    if which docker >/dev/null 2>&1; then
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

# rpc 与 秘钥
sed -i -e "s#^L1_ENDPOINT_HTTP=.*#L1_ENDPOINT_HTTP=$http_rpc#; s#^L1_ENDPOINT_WS=.*#L1_ENDPOINT_WS=$ws_rpc#; s#^ENABLE_PROVER=false.*#ENABLE_PROVER=true#; s#^L1_PROPOSER_PRIVATE_KEY=.*#L1_PROPOSER_PRIVATE_KEY=$private_key#" .env
sed -i "s|L1_BEACON_HTTP=.*|L1_BEACON_HTTP=${beacon_rpc}|" .env
sed -i "s|PROVER_ENDPOINTS=.*|PROVER_ENDPOINTS=${prover_endpoints}|" .env
# 钱包地址
sed -i "s|L2_SUGGESTED_FEE_RECIPIENT=.*|L2_SUGGESTED_FEE_RECIPIENT=${address}|" .env
# 成为验证者
sed -i "s|ENABLE_PROPOSER=.*|ENABLE_PROPOSER=true|" .env
sed -i "s|DISABLE_P2P_SYNC=.*|DISABLE_P2P_SYNC=false|" .env
# 修改默认端口避免端口冲突
sed -i "s|PORT_L2_EXECUTION_ENGINE_HTTP=.*|PORT_L2_EXECUTION_ENGINE_HTTP=8000|" .env
sed -i "s|PORT_L2_EXECUTION_ENGINE_WS=.*|PORT_L2_EXECUTION_ENGINE_WS=8001|" .env
sed -i "s|PORT_L2_EXECUTION_ENGINE_METRICS=.*|PORT_L2_EXECUTION_ENGINE_METRICS=8002|" .env
sed -i "s|PORT_L2_EXECUTION_ENGINE_P2P=.*|PORT_L2_EXECUTION_ENGINE_P2P=8003|" .env
sed -i "s|PORT_PROVER_SERVER=.*|PORT_PROVER_SERVER=8004|" .env
sed -i "s|PORT_PROMETHEUS=.*|PORT_PROMETHEUS=8005|" .env

sed -i "s|BLOCK_PROPOSAL_FEE=.*|BLOCK_PROPOSAL_FEE=30|" .env
sed -i "s|BOOT_NODES=.*|BOOT_NODES=enode://0b310c7dcfcf45ef32dde60fec274af88d52c7f0fb6a7e038b14f5f7bb7d72f3ab96a59328270532a871db988a0bcf57aa9258fa8a80e8e553a7bb5abd77c40d@167.235.249.45:30303,enode://500a10f3a8cfe00689eb9d41331605bf5e746625ac356c24235ff66145c2de454d869563a71efb3d2fb4bc1c1053b84d0ab6deb0a4155e7227188e1a8457b152@85.10.202.253:30303,enode://0b310c7dcfcf45ef32dde60fec274af88d52c7f0fb6a7e038b14f5f7bb7d72f3ab96a59328270532a871db988a0bcf57aa9258fa8a80e8e553a7bb5abd77c40d@167.235.249.45:30303,enode://500a10f3a8cfe00689eb9d41331605bf5e746625ac356c24235ff66145c2de454d869563a71efb3d2fb4bc1c1053b84d0ab6deb0a4155e7227188e1a8457b152@85.10.202.253:30303|" .env

echo "停止 Taiko 容器"
docker compose --profile l2_execution_engine down
docker stop simple-taiko-node-taiko_client_proposer-1 && docker rm simple-taiko-node-taiko_client_proposer-1

if [ $clear -eq 1 ]; then
    echo "删除原有数据"
    docker volume rm simple-taiko-node_grafana_data simple-taiko-node_l2_execution_engine_data simple-taiko-node_prometheus_data simple-taiko-node_zkevm_chain_prover_rpcd_data
fi

echo "运行 Taiko 节点容器"
docker compose --profile l2_execution_engine up -d >run.log 2>&1

echo "运行 Taiko proposer 节点"
docker compose up taiko_client_proposer -d >>run.log 2>&1

echo "结束部署taiko验证者节点"

sleep 5
docker logs -n 10 simple-taiko-node-taiko_client_proposer-1
