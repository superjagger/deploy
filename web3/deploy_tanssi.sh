#!/bin/bash

# curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/deploy_tanssi.sh | bash -s -- "节点名称" "生成者名称" "中继者名称"

# 节点名称
node_name=$1
# 区块生产者节点名称
producer_name=$2
# 中继链名称
relay_node_name=$3


if [ -z "$deploy_filename" ]; then
    echo "缺少参数"
    exit 1
fi

tanssi_dir=$HOME/tanssi_dir
tanssi_data=$tanssi_dir/data

mkdir -p $tanssi_dir
mkdir -p $tanssi_data

# 暂停并删除容器
docker stop tanssi
docker rm tanssi

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
