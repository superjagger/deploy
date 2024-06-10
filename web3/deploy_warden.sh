#!/bin/bash

# 部署命令行： curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/deploy_warden.sh | bash -s -- [node_name] [输入1清空数据]

node_name=$1

if [ -z "$node_name" ]; then
    echo "缺少参数: node_name"
    exit
fi

node_dir=$HOME/warden_dir
mkdir -p $node_dir

run_node_sh=$node_dir/run_warden_node.sh
service_name=warden
service_file=/lib/systemd/system/${service_name}.service

if [ $2 -eq 1 ]; then
    echo "本次脚本会删除原有数据，如果不想删除及时退出脚本"
    sleep 1
    echo "3"
    sleep 1
    echo "2"
    sleep 1
    echo "1"
    sudo systemctl stop ${service_name}
    rm $run_node_sh
    rm $service_file
    sudo systemctl daemon-reload
    rm -rf $HOME/.warden
fi

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
sudo apt-get install clang cmake build-essential git screen lz4 cargo -y

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

peers="95a07ae64b74f7ba6f885b73d63ee279da2f1b16@88.99.61.53:26656,4b477a8898fe3d160bfc87a3b7a2f293b8292d48@172.20.28.223:26656,650c66dda5f7aa954f44fd6148a6f32b085ca792@172.20.239.158:26656,329bd3591072b097eb4aaf1e4a3a9b388b603863@89.58.51.28:26652,3c4c0c8fa63f7a6e1045506373b576612c188e60@4.206.216.119:26656,664eff3d367e1fdd20062e9c187ae2d44b6f12dd@65.109.104.111:26656,62d162f71dec94694e581fc4a63a0599c95ff520@95.217.35.179:27356,1c6b8f381712cee1c36ce47dcd5ec4f75a6cbf1a@92.114.97.226:26656,bda08962882048fea4331fcf96ad02789671700e@65.21.202.124:35656,6f3f4997a9ddd69aca494f09a0ed7bde2df9686c@51.89.155.177:21356,5c2a752c9b1952dbed075c56c600c3a79b58c395@95.214.55.157:26956,194b68f0df274d1d169b08681f3b7b13e1f25b06@95.165.89.222:26686,8a10e74d02e2830ee4dbe3d2adf999169ba46a00@37.60.243.110:26656,a80abf96fd8996bb965f04e7061224cbb9782efc@27.79.160.157:11656,36ed0ffc019e65cd34590fc37218c457ef6b4cdc@5.252.118.128:36656,057763fb03a60008d188471309299b0006ad7796@65.109.83.40:27356,d7b524509cb70844db80a6414081e2273d1ba8e2@213.199.53.137:26656,905c98a405db505d648a4996525e879070ceb330@171.237.215.130:26656,5d19e305ba809346d419853c4bc34480ed08c84e@207.244.224.103:26656,482dd68428f2dd4d7439ca73ff254c21c5a6836c@45.159.228.46:26656"
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
# 启动节点
wardend start
EOF

# 写入服务
cat >$service_file <<EOF
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
