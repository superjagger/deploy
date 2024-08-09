#!/bin/bash

service_name=shardeum
node_dir=$HOME/${service_name}_dir
mkdir -p $node_dir

# run_node_sh=$node_dir/run_${service_name}_node.sh
# service_file=/lib/systemd/system/${service_name}.service

# 安装docker
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_docker.sh | bash

rm -rf ~/.shardeum
# 安装shardeum
cd $node_dir
echo "开始"
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/deploy_shardeum_installer.sh | bash
echo "结束"
exit 0
