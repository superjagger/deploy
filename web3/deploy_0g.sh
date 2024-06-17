#!/bin/bash

# 系统: Debian
# 项目: 0g
# 备注: 只是部署没有成为验证者
# 执行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/debian_deploy_0g.sh | bash -s -- "节点名称" 

source $HOME/.bash_profile

echo "部署0g节点开始"

# 节点配置，节点名称和钱包名称都用第一个参数
node_name=$1
wallet=$node_name
node_address="tcp://127.0.0.1:13457"

_0g_dir=$HOME/0g_dir
run_node_sh=$_0g_dir/run_0g_node.sh
mkdir -p $_0g_dir
cd $_0g_dir

if [ -z "$node_name" ]; then
    echo "缺少参数"
    exit 1
fi

# 删除原有节点
echo "清理0g原有安装数据"
sudo systemctl stop 0g.service
sudo systemctl disable 0g.service
sudo rm -rf /etc/systemd/system/0g.service
sudo rm $(which 0g)
sudo rm -rf $HOME/.evmosd

# 基本包安装
sudo apt-get install -y unzip wget lz4 git sshpass expect

# 安装go
go_version=1.22.2 # 设定go版本号
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_go_version.sh | bash -s -- $go_version
go_dir=/usr/local/go_${go_version}
export PATH=$PATH:${go_dir}/go/bin:$HOME/go/bin # 将go的目录临时添加到环境变量中，只保存当前命令行窗口

# 下载源码进行部署，这里使用我的备份包，原来0g官方github已经被封了。
echo "下载0g二进制进行安装"
git clone -b v0.1.0 https://github.com/0glabs/0g-chain.git
cd 0g-chain
make install

### 初始化节点
# 设置链ID
0gchaind init $node_name --chain-id zgtendermint_16600-1
0gchaind config chain-id zgtendermint_16600-1
0gchaind config node $node_address

# 配置节点
wget -O ~/.0gchain/config/genesis.json https://github.com/0glabs/0g-chain/releases/download/v0.1.0/genesis.json
0gchaind validate-genesis
wget https://smeby.fun/0gchaind-addrbook.json -O $HOME/.0gchain/config/addrbook.json

SEEDS="c4d619f6088cb0b24b4ab43a0510bf9251ab5d7f@54.241.167.190:26656,44d11d4ba92a01b520923f51632d2450984d5886@54.176.175.48:26656,f2693dd86766b5bf8fd6ab87e2e970d564d20aff@54.193.250.204:26656,f878d40c538c8c23653a5b70f615f8dccec6fb9f@54.215.187.94:26656"
PEERS="1b1d5996e51091b498e635d4ee772d3951e54d47@62.171.142.222:12656,3b0fd60499e74b773b85f4741d6b934f5e226912@158.220.109.208:12656,3cbb3424411d1131a40dd867ef01fd3fc505bed0@77.237.238.41:33556,2d1f251c61b707e2c3521b1f5d8d431765366bfd@193.233.164.82:26656,e0f225fb7356ab47328277f0a3df0e81e9ba67e3@65.109.35.243:26656,bccca94165140b3507bcee0982508c819671b1db@95.217.113.104:56656,8956c62a1e02a7798da2007c408fe011fbb6ab28@65.21.69.53:14256,4908344350e7792a1c462dc4f1e779c2fd3d0566@45.140.185.171:12656,d1f036c8cabf9c51d85e4f03f4e313ca6b39cf27@207.180.254.230:12656,532ae7cf25ee141f8ce36153d93a6855281e7f2d@185.197.195.172:26656,af0249c7631f4469eed8d5cf1c1582df47090551@194.163.174.51:12656,acff2b2b3c01d4903cdfd61cc9d2d0c4383f4dc4@65.108.245.136:26656,4aef094b685ab73031093f01723a63e9d1d308d9@62.169.31.83:26656,4a0010b186d3abc0aad75bb2e1f6743d6684b996@116.202.196.217:12656,de24f369f6ce5e4874a9f935d0dd2949f6e62af7@95.217.104.49:37656" 
sed -i "s/persistent_peers = .*\"\"/persistent_peers = \"$PEERS\"/" $HOME/.0gchain/config/config.toml
sed -i "s/seeds = .*\"\"/seeds = \"$SEEDS\"/" $HOME/.0gchain/config/config.toml

# 配置端口
sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:13458\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"${node_address}\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:13460\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:13456\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":13466\"%" $HOME/.0gchain/config/config.toml
sed -i -e "s%^address = \"tcp://localhost:1317\"%address = \"tcp://0.0.0.0:13417\"%; s%^address = \":8080\"%address = \":13480\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:13490\"%; s%^address = \"localhost:9091\"%address = \"0.0.0.0:13491\"%; s%:8545%:13445%; s%:8546%:13446%; s%:6065%:13465%" $HOME/.0gchain/config/app.toml

# 下载快照文件
0gchaind tendermint unsafe-reset-all --home $HOME/.0gchain --keep-addr-book
curl https://snapshots-testnet.nodejumper.io/0g-testnet/0g-testnet_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.0gchain

cd $_0g_dir
# 编写节点启动脚本
cat >$run_node_sh <<EOF
source $HOME/.bash_profile
go_dir=/usr/local/go_${go_version}
export PATH=\$PATH:\${go_dir}/go/bin:\$HOME/go/bin
# 启动节点
0gchaind start
EOF

# 写入服务
sudo cat >/lib/systemd/system/0g.service <<EOF
[Unit]
Description=0g Service

[Service]  
User=root
Type=simple
WorkingDirectory=${_0g_dir}
ExecStart=/usr/bin/bash ${run_node_sh}
Restart=on-abort
StandardOutput=syslog
StandardError=syslog
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd 并启用并启动服务
sudo systemctl daemon-reload
sudo systemctl enable 0g.service
sudo systemctl start 0g.service
sudo systemctl status 0g.service
# sudo systemctl stop 0g.service
# journalctl -u 0g.service -f -n 10

echo "部署0g节点完成"
sleep 5
journalctl -u 0g.service -n 10 --no-pager
