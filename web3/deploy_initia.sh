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

# if [ -f $run_node_sh ]; then
#     echo "已部署 initiad ，只进行服务重启"
#     sudo systemctl restart initiad
#     echo "成功重启"
#     exit
# fi
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
PEERS="a63a6f6eae66b5dce57f5c568cdb0a79923a4e18@peer-initia-testnet.trusted-point.com:26628,439fe02b731d7f99a62e44ac5b2e1b02353ca631@38.242.251.179:39656,4db605b6f399a173cfc30e843a7d6a10cd3222a3@158.220.86.6:17956,fd14410d3d6ba362a20d47c02e077da86017cadf@65.21.244.157:17956,a8638b4701f2d11e9269dfd4c2ed0509bd7b12d9@194.163.191.117:39656,0ce5a28686d961d0f1315069c03adb74c6fccc80@37.60.244.91:24556,de31968f3b35942b5a1123998ff0c4ebd3c3aae5@88.99.193.146:26656,f396faca04598721481e714dcb0e3c8ed05a406c@49.12.209.114:15656,fd06e3e5f03b31757ee2ce78d0bf85bb1c71a2d9@65.109.166.136:26656,0d5b90a3b620a7e602f099eb4da99fc03995874e@165.22.245.86:17956,028999a1696b45863ff84df12ebf2aebc5d40c2d@37.27.48.77:26656,7033bed7fa79360e24d5d0cf2f5fee8a683766a9@154.26.129.223:17956,1376a7400ee5400e226ebab384ad89de408163dc@62.171.179.87:13656,23251217584bc066c8027cc735ca1b2893896178@185.197.251.195:17956,277ae7258c9ac789262ef125cfdbf1c02958510a@37.27.71.199:22656,32fece76b6d278672fb73059764f5d6f77086f3a@148.251.3.125:19656,c612c1c6ad4a59fb62a31428782921591e8bb684@42.117.19.109:10656,fa69efe26762f987a1e1eaf4ea053b35380838dc@80.65.211.232:17956,0d6437ca9242b5878f6c784b88e918ba12f12c08@89.58.63.240:53456,f24e92c2b15ea8f212ec63ebae5451d8fcc7da8b@81.0.248.152:39656,ba053d26fe5c30842ddcc2c34c9893d78204ced0@157.90.154.36:17956,32f59b799e6e840fb47b363ba59e45c3519b3a5f@136.243.104.103:24556,5c2a752c9b1952dbed075c56c600c3a79b58c395@195.3.221.9:26686,862d16bec51e4e2751b00605416df94b7440b7f3@49.13.147.156:39656,1813a8de79d48674f184553800122f7bf794cd57@213.199.52.16:26656,a633694e4f10060023b3c8319ae130fa927f706b@207.180.251.85:17956,22c876f711032026c54d2ccfe81cb2cfe1ec9ac1@37.60.243.170:26656,15a9693fbcdd9d8aea48030be3b520b1d69e8d66@193.34.213.228:14656,98f0f8e9209aa0a8abad39b94b0d2663a3be24ec@95.216.70.202:26656,c2a36ef8b4aaef3acc7d7cbfd77d10cf4cedaa3d@77.237.235.205:53456,8999ddce339185140913a64c623d0cb2a0e104f5@185.202.223.117:17956,04538a79c786a781345533aecff034379023e661@65.108.126.173:53456,670d532665a0f93ccbba6d132109c207301d6353@194.163.170.113:17956,4d98be9bf94c8ec06f7bbd96a9b4de507d2035b8@37.60.252.43:39656,7d097908682ef4f4e168f2136da2612ec43da27c@85.215.181.21:26656,7f194243f4d9ffbe15412fc5a11eec5c914c9300@167.86.114.207:17956,a3f2bd6fcf79eec06a5f384b3edaf1fe6e4ac9ce@82.208.22.54:17956,6dbb770a4b19f685c1cfe3a16738022eb9ca12e2@101.44.82.135:53456,ef4a25ea7000773cb6094dd5d905686ab7426541@158.220.122.90:14656,2bc4ca9a821b56e5786378a4167c57ef6e0d174f@167.235.200.43:17956,e3ee807b6f4e5a5f76e3e3b73da23a07488f01fb@5.75.170.27:17956,9228bbd89be619dd943e44633585c1657051a7d0@173.212.193.103:17956,cbba1ec1e228e01b31d22864c36fb7039088a5aa@194.163.152.41:53456,ae241bcfd5fffef3173c5bd4c72b0b384db5db88@49.13.213.52:26656" && \
sed -i \
    -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" \
    "$HOME/.initia/config/config.toml"


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
CPUQuota=100%
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

