#!/bin/bash

# artela 节点部署脚本
# 部署命令行： curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/deploy_artela.sh | bash -s -- [节点名称，数字+英文最好] [是否重装，1 表示重装节点]

# 节点配置
node_name=$1

if [ -z "$node_name" ]; then
    echo "缺少参数"
    exit 1
fi

# 创建文件目录
artela_dir=$HOME/artela_dir
mkdir -p $artela_dir
# 启动脚本
run_node_sh=$artela_dir/run_artela_node.sh

if [ "$2" -eq 1 ]; then
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

if [ -f $run_node_sh ]; then
    echo "已部署 artelad ，只进行服务重启"
    sudo systemctl restart artelad
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
git checkout v0.4.7-rc6
make install

artelad config chain-id artela_11822-1
artelad init "$node_name" --chain-id artela_11822-1
artelad config node tcp://localhost:3457

# 获取初始文件和地址簿
curl -L https://snapshots-testnet.nodejumper.io/artela-testnet/genesis.json >$HOME/.artelad/config/genesis.json
curl -L https://snapshots-testnet.nodejumper.io/artela-testnet/addrbook.json >$HOME/.artelad/config/addrbook.json

# 配置节点
SEEDS=""
PEERS="5c9b1bc492aad27a0197a6d3ea3ec9296504e6fd@artela-testnet-peer.itrocket.net:30656,669fb71a6489b4fba0de5e53fcfd9f8e24cef292@207.180.212.162:26656,6ff8f4785934cf4b8ae27e28a5b041b1b271dbdd@75.119.153.252:45656,23ec079ed59a326f0e0a31dcab7e6e3165d45904@128.199.183.214:26656,b7cfd5e4d9bf7ee725c9ee8c3a86b84fdc44319c@43.242.96.234:26656,17c071b9815b680e5402158287658cee78114ccf@47.88.58.36:26656,bbf8ef70a32c3248a30ab10b2bff399e73c6e03c@65.21.198.100:23456,df31e029240ab2940cfd4df8f13617227fcf08d8@135.125.97.162:11656,3e57b70ff03e399a72eb53d0eca361af1786f07a@91.190.156.180:41656"
sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.artelad/config/config.toml

# 下载快照
mv $HOME/.artelad/data/priv_validator_state.json $HOME/.artelad/priv_validator_state.json.backup
curl -L https://snapshots-testnet.nodejumper.io/artela-testnet/artela-testnet_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.artelad
mv $HOME/.artelad/priv_validator_state.json.backup $HOME/.artelad/data/priv_validator_state.json

cd $artela_dir
# 编写节点启动脚本
cat >$run_node_sh <<EOF
source $HOME/.bash_profile
go_dir=/usr/local/go_${go_version}
export PATH=\$PATH:\${go_dir}/go/bin:\$HOME/go/bin
# 启动节点
artelad start
EOF

# 写入服务
sudo tee /lib/systemd/system/artelad.service >/dev/null <<EOF
[Unit]
Description=artelad Service

[Service]  
CPUQuota=100%
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
# sudo systemctl stop artela
# journalctl -u artelad -f -n 10

echo "部署结束"
sleep 5
journalctl -u artelad -n 10 --no-pager
