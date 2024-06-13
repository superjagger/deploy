#!/bin/bash

# ritual 节点部署
# curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/deploy_ritual.sh | bash -s -- "[私钥]" "[docker hub用户名]" "[docker hub密码]"

private_key=$1
docker_hub_username=$2
docker_hub_password=$3

if [ -z "$docker_hub_password" ]; then
    echo "缺少参数"
    exit 1
fi

service_name=ritual
node_dir=$HOME/${service_name}_dir
mkdir -p $node_dir

# 安装docker
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_docker.sh | bash

# 更新系统包列表
sudo apt-get update
sudo apt-get install git -y

cd $node_dir
# 克隆 ritual-net 仓库
git clone https://github.com/ritual-net/infernet-node
cd infernet-node
cd deploy

# 使用cat命令将配置写入config.json
cat >config.json <<EOF
{
  "log_path": "infernet_node.log",
  "manage_containers": true,
  "server": {
    "port": 4000,
    "rate_limit": {
      "num_requests": 100,
      "period": 100
    }
  },
  "chain": {
    "enabled": true,
    "trail_head_blocks": 5,
    "rpc_url": "http://127.0.0.1:8545",
    "registry_address": "0x3B1554f346DFe5c482Bb4BA31b880c1C18412170",
    "coordinator_address": "0x8D871Ef2826ac9001fB2e33fDD6379b6aaBF449c",
    "wallet": {
      "max_gas_limit": 5000000,
      "private_key": "0x${private_key}",
      "allowed_sim_errors": ["not enough balance"]
    },
    "snapshot_sync": {
      "sleep": 1.5,
      "batch_size": 200
    }
  },
  "docker": {
    "username": "username",
    "password": "password"
  },
  "redis": {
    "host": "redis",
    "port": 6379
  },
  "forward_stats": true,
  "startup_wait": 1.0,
  "containers": [
    {
      "id": "hello-world",
      "image": "ritualnetwork/hello-world-infernet:latest",
      "external": true,
      "port": "3000",
      "allowed_delegate_addresses": [],
      "allowed_addresses": [],
      "allowed_ips": [],
      "command": "--bind=0.0.0.0:3000 --workers=2",
      "env": {},
      "volumes": [],
      "accepted_payments": {
        "0x0000000000000000000000000000000000000000": 1000000000000000000,
        "0x59F2f1fCfE2474fD5F0b9BA1E73ca90b143Eb8d0": 1000000000000000000
      },
      "generates_proofs": false
    }
  ]
}
EOF


# 启动容器
docker compose up -d
