#!/bin/bash

service_name=elixir
node_dir=$HOME/${service_name}_dir
mkdir -p $node_dir

# 安装docker
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_docker.sh | bash

address=$1
private_key=$2
node_name=$3
cd $node_dir
cat > Dockerfile <<EOF
FROM elixirprotocol/validator:testnet-2

ENV ADDRESS=$address
ENV PRIVATE_KEY=$private_key
ENV VALIDATOR_NAME=$node_name
EOF

docker build . -f Dockerfile -t elixir-validator
docker run -it -d --name ev elixir-validator
