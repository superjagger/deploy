#!/bin/bash

# initia 节点部署脚本
# 部署命令行： curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/deploy_initia.sh | bash

# 关闭防火墙
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/stop_firewall.sh | bash

# 创建文件目录
initia_dir=$HOME/initia_dir
mkdir -p $initia_dir
# 启动脚本
run_node_sh=$initia_dir/run_initia_node.sh

if [ -f $run_node_sh ]; then
    echo "已部署 initiad，只进行服务重启"
    sudo systemctl restart initiad
    echo "成功重启"
    exit
fi

echo "开始部署 initiad"

# 清理环境变量中的go版本
go_version=1.22.2 # 设定go版本号
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_go_version.sh | bash -s -- $go_version
go_dir=/usr/local/go_${go_version}
export PATH=$PATH:${go_dir}/go/bin:$HOME/go/bin # 将go的目录临时添加到环境变量中，只保存当前命令行窗口

# 更新和安装必要的软件
apt-get update && apt upgrade -y
apt-get install -y curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev lz4 snapd

cd $initia_dir

# 安装所有二进制文件
git clone https://github.com/initia-labs/initia
cd initia
git checkout v0.2.12
make install
initiad version

# 配置initiad
initiad init "Moniker" --chain-id initiation-1
initiad config set client chain-id initiation-1

# 获取初始文件和地址簿
wget -O $HOME/.initia/config/genesis.json https://initia.s3.ap-southeast-1.amazonaws.com/initiation-1/genesis.json
wget -O $HOME/.initia/config/addrbook.json https://rpc-initia-testnet.trusted-point.com/addrbook.json
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.15uinit,0.01uusdc\"|" $HOME/.initia/config/app.toml

# 配置节点
PEERS="40d3f977d97d3c02bd5835070cc139f289e774da@168.119.10.134:26313,841c6a4b2a3d5d59bb116cc549565c8a16b7fae1@23.88.49.233:26656,e6a35b95ec73e511ef352085cb300e257536e075@37.252.186.213:26656,2a574706e4a1eba0e5e46733c232849778faf93b@84.247.137.184:53456,ff9dbc6bb53227ef94dc75ab1ddcaeb2404e1b0b@178.170.47.171:26656,edcc2c7098c42ee348e50ac2242ff897f51405e9@65.109.34.205:36656,07632ab562028c3394ee8e78823069bfc8de7b4c@37.27.52.25:19656,028999a1696b45863ff84df12ebf2aebc5d40c2d@37.27.48.77:26656,140c332230ac19f118e5882deaf00906a1dba467@185.219.142.119:53456,1f6633bc18eb06b6c0cab97d72c585a6d7a207bc@65.109.59.22:25756,065f64fab28cb0d06a7841887d5b469ec58a0116@84.247.137.200:53456,767fdcfdb0998209834b929c59a2b57d474cc496@207.148.114.112:26656,093e1b89a498b6a8760ad2188fbda30a05e4f300@35.240.207.217:26656,12526b1e95e7ef07a3eb874465662885a586e095@95.216.78.111:26656"
sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.initia/config/config.toml

# 配置端口
node_address="tcp://localhost:53457"
sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:53458\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:53457\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:53460\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:53456\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":53466\"%" $HOME/.initia/config/config.toml
sed -i -e "s%^address = \"tcp://localhost:1317\"%address = \"tcp://0.0.0.0:53417\"%; s%^address = \":8080\"%address = \":53480\"%; s%^address = \"localhost:9090\"%address = \"0.0.0.0:53490\"%; s%^address = \"localhost:9091\"%address = \"0.0.0.0:53491\"%; s%:8545%:53445%; s%:8546%:53446%; s%:6065%:53465%" $HOME/.initia/config/app.toml

export initiad_RPC_PORT=$node_address

cd $initia_dir
slinky_dir=$initia_dir/slinky
# 配置预言机
git clone https://github.com/skip-mev/slinky.git
cd $slinky_dir

# checkout proper version
git checkout v0.4.3

make build

# 配置预言机启用
sed -i -e 's/^enabled = "false"/enabled = "true"/' \
    -e 's/^oracle_address = ""/oracle_address = "127.0.0.1:8080"/' \
    -e 's/^client_timeout = "2s"/client_timeout = "500ms"/' \
    -e 's/^metrics_enabled = "false"/metrics_enabled = "false"/' $HOME/.initia/config/app.toml

# 配置快照
sudo apt install lz4 -y
wget -O initia_120971.tar.lz4 https://snapshots.polkachu.com/testnet-snapshots/initia/initia_120971.tar.lz4 --inet4-only
initiad tendermint unsafe-reset-all --home $HOME/.initia --keep-addr-book
lz4 -c -d initia_120971.tar.lz4 | tar -x -C $HOME/.initia


cd $initia_dir
# 编写节点启动脚本
cat >$run_node_sh <<EOF
go_dir=/usr/local/go_${go_version}
export PATH=\$PATH:\${go_dir}/go/bin:\$HOME/go/bin
source $HOME/.bash_profile
# 启动节点
initiad start
EOF

# 写入服务
sudo tee /lib/systemd/system/initiad.service >/dev/null <<EOF
[Unit]
Description=initiad Service

[Service]  
CPUQuota=40%
User=root
Type=simple
WorkingDirectory=${initia_dir}
ExecStart=/usr/bin/bash run_initia_node.sh
Restart=on-abort
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=initiad
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd 并启用并启动服务
sudo systemctl daemon-reload
sudo systemctl enable initiad
sudo systemctl restart initiad
sudo systemctl status initiad
# sudo systemctl stop initiad
# journalctl -u initiad -f -n 10
