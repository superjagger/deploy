#!/bin/bash

# 系统：Debian
# docker 安装脚本，执行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/debian_deploy_eigenlayer.sh | bash
source $HOME/.bash_profile

echo "安装基础包"
sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get install git -y

echo "安装go"
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_go.sh | bash

echo "安装docker"
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/debian_deploy_docker.sh | bash

echo "安装eigenlayer"
cd $HOME
rm -rf eigenlayer-cli
git clone https://github.com/Layr-Labs/eigenlayer-cli.git
cd eigenlayer-cli
mkdir -p build
go build -o build/eigenlayer cmd/eigenlayer/main.go
cp ./build/eigenlayer /usr/local/bin/
cd $HOME
eigenlayer
