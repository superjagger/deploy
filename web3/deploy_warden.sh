#!/bin/bash

# 部署命令行： curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/deploy_titan.sh | bash -s -- [node_name]

node_name=$1

if [ -z "$node_name" ]; then
    echo "缺少参数: node_name"
    exit
fi

node_dir=$HOME/warden_dir
mkdir -p $node_dir

run_node_sh=$node_dir/run_warden_node.sh
service_name=warden

if [ -f $run_node_sh ]; then
    echo "${service_name} 已部署"
    # 判断服务是否运行
    output=$(systemctl is-active ${service_name})
    # 判断输出是否为 "active"，从而确定服务是否启用
    if [ "$output" = "active" ]; then
        echo "${service_name} 服务已启用"
    else
        echo "${service_name} 服务没有启用，重启服务"
        sudo systemctl start ${service_name}
        echo "成功重启"
    fi

    sleep 10
    sudo systemctl status ${service_name}
    journalctl -u ${service_name} -n 10 --no-pager
    exit
fi

# 安装前置
sudo apt-get update
sudo apt-get install clang cmake build-essential git screen cargo -y
sudo apt-get install git -y

# 安装go
go_version=1.22.2 # 设定go版本号
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_go_version.sh | bash -s -- $go_version
go_dir=/usr/local/go_${go_version}
export PATH=$PATH:${go_dir}/go/bin:$HOME/go/bin # 将go的目录临时添加到环境变量中

# 下载源码并编译
cd $node_dir
git clone --depth 1 --branch v0.3.0 https://github.com/warden-protocol/wardenprotocol
cd wardenprotocol
make install
wardend version
wardend init $node_name --chain-id buenavista-1

# 修改配置
wget -O $HOME/.warden/config/genesis.json "https://raw.githubusercontent.com/warden-protocol/networks/main/testnets/buenavista/genesis.json"
wget -O $HOME/.warden/config/addrbook.json "https://share.utsa.tech/warden/addrbook.json"

external_address=$(wget -qO- eth0.me)
sed -i.bak -e "s/^external_address *=.*/external_address = \"$external_address:26656\"/" $HOME/.warden/config/config.toml

peers="b14f35c07c1b2e58c4a1c1727c89a5933739eeea@warden-testnet-peer.itrocket.net:18656,61446070887838944c455cb713a7770b41f35ac5@37.60.249.101:26656,8288657cb2ba075f600911685670517d18f54f3b@65.108.231.124:18656,0be8cf6de2a01a6dc7adb29a801722fe4d061455@65.109.115.100:27060"
sed -i -e "s|^persistent_peers *=.*|persistent_peers = \"$peers\"|" $HOME/.warden/config/config.toml
seeds="8288657cb2ba075f600911685670517d18f54f3b@warden-testnet-seed.itrocket.net:18656"
sed -i.bak -e "s/^seeds =.*/seeds = \"$seeds\"/" $HOME/.warden/config/config.toml
sed -i -e "s/^filter_peers *=.*/filter_peers = \"true\"/" $HOME/.warden/config/config.toml

pruning="custom"
pruning_keep_recent="1000"
pruning_interval="10"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.warden/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.warden/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.warden/config/app.toml

sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.0025uward\"/;" ~/.warden/config/app.toml

# 下载快照
curl -o - -L https://config-t.noders.services/warden/data.tar.lz4 | lz4 -d | tar -x -C ~/.warden


# 编辑启动命令
cat >$run_node_sh <<EOF
export PATH=\$PATH:${go_dir}/go/bin:\$HOME/go/bin 
cd $node_dir/wardend
# 启动节点
wardend start
EOF

# 写入服务
cat >/lib/systemd/system/${service_name}.service <<EOF
[Unit]
Description=${service_name} Service

[Service]  
CPUQuota=200%
User=root
Type=simple
Restart=always
RestartSec=5S
WorkingDirectory=${node_dir}
Environment=GOEXPERIMENT=arenas
ExecStart=/usr/bin/bash $run_node_sh
[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd 并启用并启动服务
sudo systemctl daemon-reload
sudo systemctl enable ${service_name}
sudo systemctl restart ${service_name}
# sudo systemctl stop ${service_name}
# journalctl -u ${service_name} -f -n 10

# 输出运行日志
sleep 5
sudo systemctl status ${service_name}
journalctl -u ${service_name} -n 10 --no-pager
