#!/bin/bash

# 系统: Debian
# 项目: 0g
# 备注: 只是部署没有成为验证者
# 执行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/debian_deploy_0g.sh | bash -s -- \"节点名称\" "109.199.124.193服务器密码"

echo "部署0g节点开始"
# 删除原有节点
sudo systemctl stop ogd.service
sudo systemctl disable ogd.service
sudo rm -rf /etc/systemd/system/ogd.service
sudo rm $(which ogd)
sudo rm -rf $HOME/.evmosd

# 基本包安装
sudo apt-get install -y unzip wget lz4 git sshpass

# 安装go
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_go.sh | bash

# 节点配置，节点名称和钱包名称都用第一个参数
node_name=$1
chain_id="zgtendermint_9000-1"
rpc_port=26657

_0g_dir=$HOME/0g_dir

mkdir -p $_0g_dir

cd $_0g_dir

gz_server_password=$2

if [ -z "$node_name" ] || [ -z "$gz_server_password" ]; then
  echo "缺少参数"
  exit 1
fi

# 下载源码进行部署，这里使用我的备份包，原来0g官方github已经被封了。
sshpass -p "${gz_server_password}" scp -r root@109.199.124.193:/root/0g_dir/test.tar.gz $_0g_dir/0g.tar.gz  >>downloads.log 2>&1 &
tar -zxvf test.tar.gz
rm test.tar.gz
bash ./0g-evmos/networks/testnet/install.sh

### 初始化节点
# 设置链ID
evmosd config chain-id ${chain_id}

# 节点名称
evmosd init ${node_name} --chain-id ${chain_id}

evmosd config node tcp://localhost:${rpc_port}
evmosd config keyring-backend os

### 节点配置
# 下载创世文件配置
wget https://snapshots-testnet.nodejumper.io/0g-testnet/genesis.json -O $HOME/.evmosd/config/genesis.json

# 修改种子与同步节点配置
peers="1248487ea585730cdf5d3c32e0c2a43ad0cda973@peer-zero-gravity-testnet.trusted-point.com:26326"
seeds="8c01665f88896bca44e8902a30e4278bed08033f@54.241.167.190:26656,b288e8b37f4b0dbd9a03e8ce926cd9c801aacf27@54.176.175.48:26656,8e20e8e88d504e67c7a3a58c2ea31d965aa2a890@54.193.250.204:26656,e50ac888b35175bfd4f999697bdeb5b7b52bfc06@54.215.187.94:26656"
sed -i -e "s/^seeds *=.*/seeds = \"$seeds\"/; s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.evmosd/config/config.toml

# 设置gas
sed -i "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.00252aevmos\"/" $HOME/.evmosd/config/app.toml

# 下载最新快照
wget -O latest_snapshot.tar.lz4 https://snapshots-testnet.nodejumper.io/0g-testnet/0g-testnet_latest.tar.lz4  >>downloads.log 2>&1 &

# 备份当前的验证者状态文件
cp $HOME/.evmosd/data/priv_validator_state.json $HOME/.evmosd/priv_validator_state.json.backup

# 重置数据目录同时保留地址簿
evmosd tendermint unsafe-reset-all --home $HOME/.evmosd --keep-addr-book

# 将快照解压直接到 .evmosd 目录
lz4 -d -c ./latest_snapshot.tar.lz4 | tar -xf - -C $HOME/.evmosd

# 恢复验证者状态文件的备份
mv $HOME/.evmosd/priv_validator_state.json.backup $HOME/.evmosd/data/priv_validator_state.json

# 删除下载的快照
rm latest_snapshot.tar.lz4

# 添加守护服务
sudo tee /etc/systemd/system/ogd.service >/dev/null <<EOF
[Unit]
Description=OG Node
After=network.target

[Service]
User=$USER
Type=simple
ExecStart=$(which evmosd) start --home $HOME/.evmosd
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable ogd.service
sudo systemctl restart ogd.service

echo "部署0g节点结束"
