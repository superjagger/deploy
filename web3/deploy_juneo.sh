#!/bin/bash

# juneo 节点部署
# curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/deploy_juneo.sh | bash -s -- "[助记词]"

mnemonic=$1
echo "部署助记词: ${mnemonic}"

juneo_dir=$HOME/juneo_dir
mkdir -p $juneo_dir

# 安装docker
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_docker.sh | bash

# 安装nodejs
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_node.sh | bash

source $HOME/.bash_profile
# 安装基础组件
apt-get install git

# 检查是否有运行的juneogo容器
if [[ -n $(docker ps -q -f "name=^juneogo$") ]]; then
    echo "juneogo节点已经部署"
    exit
fi

# 删除所有juneogo容器
docker rm $(sudo docker ps -a -q -f "name=^.*juneogo$" | awk '{print $1}')

echo "下载源码，部署节点"
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

echo "部署结束"
sleep 5
docker logs juneogo -n 10

echo "启动状态"
curl -X POST --data '{
    "jsonrpc":"2.0",
    "id"     :1,
    "method" :"info.isBootstrapped",
    "params": {
        "chain":"JUNE"
    }
}' -H 'content-type:application/json;' 192.168.10.2:9650/ext/info
echo "查询 node-id"
curl -X POST --data '{
    "jsonrpc":"2.0",
    "id"     :1,
    "method" :"info.getNodeID"
}' -H 'content-type:application/json' 127.0.0.1:9650/ext/info

########### 转入水 ###########
echo "转水，准备成为职业者"
cd $juneo_dir
git clone https://github.com/Juneo-io/juneojs-examples
cd juneojs-examples
npm install
# 写入助记词，为后续成为验证者做准备
echo "MNEMONIC=\"${mnemonic}\"" >.env
# 转水
echo "还没领水脚本待完成"
