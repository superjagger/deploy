#!/bin/bash

# 部署命令行： curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/deploy_allora.sh | bash -s -- 
# set -eu

service_name=allora
node_dir=$HOME/${service_name}_dir
mkdir -p $node_dir

# 更新基础包
sudo apt-get update
sudo apt-get install jq git -y

# 安装docker
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_docker.sh | bash

# 下载 docker 部署文件
cd $node_dir
git clone https://github.com/allora-network/allora-chain.git
cd allora-chain
sed -i "s|- \"26656-26657:26656-26657\"|- \"36656-36657:26656-26657\"|" docker-compose.yaml
docker compose pull
docker compose up -d

sleep 10
echo "查询秘钥"
cat data/data/sample_validator.account_info
# 状态
curl -s http://localhost:36657/status | jq .
docker logs -n 20 sample_validator
