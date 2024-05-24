#!/bin/bash

# juneo 节点部署
# curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/deploy_juneo.sh | bash -s -- "[助记词]"

mnemonic=$1

juneo_dir=$HOME/juneo_dir
mkdir -p $juneo_dir

# 安装docker
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_docker.sh | bash

# 安装nodejs
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_node.sh | bash

source $HOME/.bash_profile
# 安装基础组件
apt-get install git

########### 启动节点 ###########
# 下载源码
cd $juneo_dir
git clone https://github.com/Juneo-io/juneogo-docker
cd juneogo-docker
# 放开端口注释
sed -i "s|# - 9650:9650|- 9650:9650|" docker-compose.yml
# 编译并启动juneo docker
docker compose build
docker compose up -d juneogo
sudo chown -R root juneogo/.juneogo/

sleep 5
docker logs -f juneogo -n 10

########### 转入水 ###########
# cd $juneo_dir
# git clone https://github.com/Juneo-io/juneojs-examples
# cd juneojs-examples
# npm install
# # 写入助记词
# echo "MNEMONIC=\"${mnemonic}\"" > .env
# # 转水
