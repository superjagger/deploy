#!/bin/bash

# curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/deploy_tanssi.sh | bash -s -- "节点名称" "生成者名称" "中继者名称" "是否重装，1 表示重装节点"

# 节点名称
node_name=$1
# 区块生产者节点名称
producer_name=$2
# 中继链名称
relay_node_name=$3

echo "$node_name  $producer_name  $relay_node_name"

if [ -z "$relay_node_name" ]; then
    echo "缺少参数"
    exit 1
fi

clear=$4
if [ -z "$clear" ]; then
    clear=0
fi

tanssi_dir=$HOME/tanssi_dir
tanssi_data=$tanssi_dir/data

mkdir -p $tanssi_dir
mkdir -p $tanssi_data

if [ $clear -eq 1 ]; then
    echo "本次脚本会删除原有数据，如果不想删除及时退出脚本"
    sleep 1
    echo "3"
    sleep 1
    echo "2"
    sleep 1
    echo "1"
    # 暂停并删除容器
    docker stop tanssi
    docker rm tanssi
fi

# 安装docker
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_docker.sh | bash

# 检查是否有部署的tanssi容器
if [[ -n $(docker ps -a -q -f "name=tanssi") ]]; then
    echo "tanssi节点已经部署，只进行启动服务"
    docker start tanssi
    exit
fi

# 启动容器
docker run -d --network="host" --name tanssi -v "$tanssi_data:/data" \
    -u $(id -u ${USER}):$(id -g ${USER}) \
    moondancelabs/tanssi \
    --chain=dancebox \
    --name=$node_name \
    --sync=warp \
    --base-path=/data/para \
    --state-pruning=2000 \
    --blocks-pruning=2000 \
    --collator \
    --telemetry-url='wss://telemetry.polkadot.io/submit/ 0' \
    --database paritydb \
    -- \
    --name=$producer_name \
    --base-path=/data/container \
    --telemetry-url='wss://telemetry.polkadot.io/submit/ 0' \
    -- \
    --chain=westend_moonbase_relay_testnet \
    --name=$relay_node_name \
    --sync=fast \
    --base-path=/data/relay \
    --state-pruning=2000 \
    --blocks-pruning=2000 \
    --telemetry-url='wss://telemetry.polkadot.io/submit/ 0' \
    --database paritydb

sleep 5
docker logs -n 10 tanssi
