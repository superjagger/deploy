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
PEERS="4d108a6199f393ec6018257db306caf9deeda268@95.216.228.91:3456,ca8bce647088a12bc030971fbcce88ea7ffdac50@84.247.153.99:26656,a3501b87757ad6515d73e99c6d60987130b74185@85.239.235.104:3456,2c62fb73027022e0e4dcbdb5b54a9b9219c9b0c1@51.255.228.103:26687,fbe01325237dc6338c90ddee0134f3af0378141b@158.220.88.66:3456,fde2881b06a44246a893f37ecb710020e8b973d1@158.220.84.64:3456,12d057b98ecf7a24d0979c0fba2f341d28973005@116.202.162.188:10656,9e2fbfc4b32a1b013e53f3fc9b45638f4cddee36@47.254.66.177:26656,92d95c7133275573af25a2454283ebf26966b188@167.235.178.134:27856,2dd98f91eaea966b023edbc88aa23c7dfa1f733a@158.220.99.30:26680"
sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.artelad/config/config.toml

# 配置裁剪
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.artelad/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.artelad/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"0\"/" $HOME/.artelad/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" $HOME/.artelad/config/app.toml
sed -i -e 's/max_num_inbound_peers = 40/max_num_inbound_peers = 100/' -e 's/max_num_outbound_peers = 10/max_num_outbound_peers = 100/' $HOME/.artelad/config/config.toml

# 下载快照
curl -L https://public-snapshot-storage-develop.s3.amazonaws.com/artela/artela_11822-1/snapshots/artela_9366339.tar.lz4 | tar -I lz4 -xf - -C $HOME/.artelad/data

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
