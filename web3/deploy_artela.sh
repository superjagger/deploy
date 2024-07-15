#!/bin/bash

# artela 节点部署脚本
# 部署命令行： curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/deploy_artela.sh | bash -s -- [节点名称，数字+英文最好] [是否重装，1 表示重装节点]

# 节点配置
node_name=$1

node_address="tcp://127.0.0.1:3457"

if [ -z "$node_name" ]; then
    echo "缺少参数"
    exit 1
fi

# 创建文件目录
artela_dir=$HOME/artela_dir
mkdir -p $artela_dir
# 启动脚本
run_node_sh=$artela_dir/run_artela_node.sh
clear=$2
if [ -z "$clear" ]; then
    clear=0
fi

if [ $clear -eq 1 ]; then
    echo "本次脚本会删除原有数据，如果不想删除及时退出脚本"
    sleep 1
    echo "3"
    sleep 1
    echo "2"
    sleep 1
    echo "1"
    sudo systemctl stop artelad
    rm -rf /lib/systemd/system/artelad.service
    rm -rf $HOME/.artelad
    rm -rf $artela_dir/artela
    rm -rf $run_node_sh
fi

if [ -f /lib/systemd/system/artelad.service ]; then
    echo "已部署 artelad ，只进行服务重启"

    # 配置端口
    sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:3458\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"$node_address\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:3460\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:3456\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":3466\"%" $HOME/.artelad/config/config.toml
    sed -i -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:3417\"%; s%^address = \":8080\"%address = \":3480\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:3490\"%; s%^address = \"localhost:9091\"%address = \"0.0.0.0:3491\"%; s%:8545%:3445%; s%:8546%:3446%; s%:6065%:3465%" $HOME/.artelad/config/app.toml

    sudo systemctl start artelad
    echo "成功重启"
    exit
fi

# 关闭防火墙
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/stop_firewall.sh | bash

# 更新和安装必要的软件
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev lz4 snapd

go_version=1.22.2 # 设定go版本号
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_go_version.sh | bash -s -- $go_version
go_dir=/usr/local/go_${go_version}
export PATH=$PATH:${go_dir}/go/bin:$HOME/go/bin # 将go的目录临时添加到环境变量中，只保存当前命令行窗口

cd $artela_dir
git clone https://github.com/artela-network/artela
cd artela
git checkout v0.4.7-rc7
make install

cd $HOME
mkdir -p $HOME/.artelad
cd $HOME/.artelad && mkdir libs && cd libs
wget https://github.com/artela-network/artela/releases/download/v0.4.7-rc7/artelad_0.4.7_rc7_Linux_amd64.tar.gz
tar -xzvf artelad_0.4.7_rc7_Linux_amd64.tar.gz
rm artelad_0.4.7_rc7_Linux_amd64.tar.gz
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/.artelad/libs

artelad config chain-id artela_11822-1
artelad init "$node_name" --chain-id artela_11822-1
artelad config node $node_address

# 获取初始文件和地址簿
curl -L https://snapshots-testnet.nodejumper.io/artela-testnet/genesis.json >$HOME/.artelad/config/genesis.json
curl -L https://snapshots-testnet.nodejumper.io/artela-testnet/addrbook.json >$HOME/.artelad/config/addrbook.json

# 配置端口
sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:3458\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"$node_address\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:3460\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:3456\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":3466\"%" $HOME/.artelad/config/config.toml
sed -i -e "s%^address = \"tcp://localhost:1317\"%address = \"tcp://0.0.0.0:3417\"%; s%^address = \":8080\"%address = \":3480\"%; s%^address = \"localhost:9090\"%address = \"0.0.0.0:3490\"%; s%^address = \"localhost:9091\"%address = \"0.0.0.0:3491\"%; s%:8545%:3445%; s%:8546%:3446%; s%:6065%:3465%" $HOME/.artelad/config/app.toml

# 配置节点
SEEDS=""
PEERS="1e7a2f2ed7413cc4b06b8c82b0b2f81605ce7b60@207.180.239.56:26656,678b63e026f458a7a49080b077a5bb7e5962cbb4@159.203.63.54:3456,a3b8955aa523285d0aed51c7bfaf19eb20264ef5@136.243.136.241:10656,b58fde15f949636cf2932ab1d74b97cc8b3641e6@143.110.164.203:33656,3c0fddfe8a56c7180b0976d70206cbedfacf5bc7@195.26.249.54:3456,b3211b205d2b2b08badffe806cc61a76e827a27f@178.128.127.160:33656,3df5dd67a7ab190af55c2c5d2cf0b54bb74d94d0@158.220.87.254:3456,7930c01d31898ea0d32983c4160b47f5f7d855ff@89.58.47.180:3456,64b173abafe71d5d28bc126dd07c4aa0e474dcb6@138.201.22.153:656,7bb0c9e58c7412943c609207bf1443abba0c51d1@161.97.125.252:26656,26f59fd1f0d75dec9cb4121a1f1cc40ac5710a7e@107.175.209.142:3456,0948dc5df4792f8edcd7c73b549712f7b9499aef@173.249.26.237:23456,ebb40b444569467d44e993900dd915153859112e@202.61.226.109:3456,cf221a2953560d868981ef008840da1222227d4c@149.102.129.14:3456,b8f73a3bc449c50f3b2f9d2dbde96ad5811510e3@192.53.162.80:33656,e5e07f417fed4ffd0c6d6eebbaefe95fa57ac085@84.247.182.230:45656,c035dbb813c2cf53c10917ab035fcc3adcdbed79@89.117.148.215:3456,aa0ee6067fdce8d1974350d5763eb0fce20e1bb1@161.97.157.206:3456,22e963ae2ab5adf0f9141e7949a2c0c9b247275c@45.88.223.159:26666,a9f359155cc4137be40b14e8f1a60cd376630cf8@74.208.49.38:33656,3eb4c0108f7f54e43e259b6a9c6a231752b0bc1a@65.21.84.94:10256,3a97fe53c08b004be7a127c4d4fe2e72ab875520@156.67.82.187:3456,e75731bea99f66e70bc6e5500edd7c32b67d744a@46.38.234.173:3456,00bf37502e023ea690a0cb8b7c2195747defb848@161.97.162.96:23456,a6bdeabb9017dc3ab64ac1dbd00cae0b98282e51@38.242.211.64:3456,7f6cc8c8da9d6d674cc91a7df29b314468a522db@138.197.77.22:14656,f8ce6e3fa698e4a7168aafbb478a8a7b493026db@163.204.219.227:3456,4c1a9bf2a50e28542c77bdc573aa181a939a4928@152.53.46.134:3456,93ac7582a9d003d45c5504b423aba639e54ff0be@194.238.24.181:3456,74f64e54b9da557e517697a2318f58f7fe8af9f1@188.166.237.143:26656"
sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.artelad/config/config.toml

# 配置裁剪
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.artelad/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.artelad/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"0\"/" $HOME/.artelad/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" $HOME/.artelad/config/app.toml
sed -i -e 's/max_num_inbound_peers = 40/max_num_inbound_peers = 100/' -e 's/max_num_outbound_peers = 10/max_num_outbound_peers = 100/' $HOME/.artelad/config/config.toml

# 下载快照
curl -L https://snapshots.dadunode.com/artela/artela_latest_tar.lz4 | tar -I lz4 -xf - -C $HOME/.artelad/data

cd $artela_dir
# 编写节点启动脚本
cat >$run_node_sh <<EOF
source $HOME/.bash_profile
go_dir=/usr/local/go_${go_version}
export PATH=\$PATH:\${go_dir}/go/bin:\$HOME/go/bin
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$HOME/.artelad/libs
# 启动节点
artelad start
EOF

# 写入服务
sudo cat >/lib/systemd/system/artelad.service <<EOF
[Unit]
Description=artelad Service

[Service]  
CPUQuota=200%
User=root
Type=simple
WorkingDirectory=${artela_dir}
ExecStart=/usr/bin/bash ${run_node_sh}
Restart=on-abort
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=artelad
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd 并启用并启动服务
sudo systemctl daemon-reload
sudo systemctl enable artelad
sudo systemctl restart artelad
sudo systemctl status artelad
# sudo systemctl stop artelad
# journalctl -u artelad -f -n 10

echo "部署结束"
sleep 5
journalctl -u artelad -n 10 --no-pager
