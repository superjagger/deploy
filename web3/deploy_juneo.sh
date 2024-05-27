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

# 删除所有未运行的juneogo容器
sudo docker rm $(docker ps -a -f "name=^.*juneogo$" | grep -E "Exited|Create" | awk '{print $1}')

echo "下载源码，部署节点"
########### 启动节点 ###########
# 下载源码
cd $juneo_dir
git clone https://github.com/Juneo-io/juneogo-docker
cd juneogo-docker
cat >docker-compose.yml <<EOF
version: '2'
services:
  juneogo:
    build: .
    container_name: juneogo
    restart: unless-stopped
    cap_add:
      - NET_ADMIN # 允许修改带宽配置，进行限速
    ports:
      - 9650:9650 # port for API calls - will enable remote RPC calls to your node (mandatory for Supernet/ Blockchain deployers)
      - 9651:9651 # 9651 for staking

    volumes:
      - ./juneogo:/root
      - /etc/letsencrypt:/etc/letsencrypt
      - /etc/localtime:/etc/localtime:ro
    networks:
      slg-network:
        ipv4_address: 192.168.10.2

    command: bash -c "./config.sh && ./juneogo --config-file='.juneogo/config.json'"
    # Max-size of 10m and max-file of 3 to avoid filling up the disk
    logging:
      driver: 'json-file'
      options:
        max-size: '10m'
        max-file: '3'

  caddy:
    image: caddy:2.4.6
    container_name: caddy
    ports:
      - '80:80'
      - '443:443'
    volumes:
      - ./caddy/Caddyfile:/etc/caddy/Caddyfile
      - ./caddy/caddy_data:/data
      - ./caddy/caddy_config:/config
      - ./juneogo/.juneogo:/etc/juneogo-ssl:ro
    networks:
      slg-network:
        ipv4_address: 192.168.10.3

networks:
  slg-network:
    driver: bridge
    ipam:
      config:
        - subnet: 192.168.10.0/24
          gateway: 192.168.10.1
EOF

# 放开端口注释
# sed -i "s|# - 9650:9650|- 9650:9650|" docker-compose.yml
# 编译并启动juneo docker
docker compose build
docker compose up -d juneogo
sudo chown -R root juneogo/.juneogo/

echo "部署结束"
sleep 5
docker logs juneogo -n 10
# 容器带宽限速 5mb/s
echo "限制容器网速"
docker exec juneogo apt-get update && apt-get install -y wondershaper && wondershaper eth0 25600 25600 

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
