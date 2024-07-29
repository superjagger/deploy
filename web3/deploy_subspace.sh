#!/bin/bash

# 部署subspace节点
# 参考资料：https://docs.subspace.network/docs/farming-&-staking/farming/advanced-cli/cli-install/
# curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/deploy_subspace.sh | bash -s -- "[tssc地址]" "[节点名称]"


address=$1
node_name=$2
echo "参数"
echo "address: $address"
echo "node_name: $node_name"
echo "开始部署"

if [ -z "$node_name" ]; then
    echo "缺少参数"
    exit 1
fi

service_name=subspace
node_dir=$HOME/${service_name}_dir
mkdir -p $node_dir

# 安装docker
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_docker.sh | bash

# 安装shardeum
cd $node_dir
# 停止之前的容器
docker compose down
# 创建容器文件
cat >docker-compose.yaml <<EOF
services:
  node:
    image: ghcr.io/autonomys/node:
    volumes:
      - node-data:/var/subspace:rw
    ports:
      - "0.0.0.0:30333:30333/tcp"
      - "0.0.0.0:30433:30433/tcp"
    restart: unless-stopped
    command:
      [
        "run",
        "--chain", "gemini-3h",
        "--base-path", "/var/subspace",
        "--listen-on", "/ip4/0.0.0.0/tcp/30333",
        "--dsn-listen-on", "/ip4/0.0.0.0/tcp/30433",
        "--rpc-cors", "all",
        "--rpc-methods", "unsafe",
        "--rpc-listen-on", "0.0.0.0:9944",
        "--farmer",
        "--name", "${node_name}"
      ]
    healthcheck:
      timeout: 5s
      interval: 30s
      retries: 60

  farmer:
    depends_on:
      node:
        condition: service_healthy
    image: ghcr.io/autonomys/farmer:
    volumes:
      - farmer-data:/var/subspace:rw
    ports:
      - "0.0.0.0:30533:30533/tcp"
    restart: unless-stopped
    command:
      [
        "farm",
        "--node-rpc-url", "ws://node:9944",
        "--listen-on", "/ip4/0.0.0.0/tcp/30533",
        "--reward-address", "${address}",
        "path=/var/subspace,size=100G"
      ]
volumes:
  node-data:
  farmer-data:            
EOF
# 部署容器
docker compose up -d
