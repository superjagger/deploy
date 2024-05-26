#!/bin/bash

# 部署0g存储节点
# 部署命令行： curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/deploy_0g_storage.sh | bash -s -- [私钥，去掉0x开头] [是否重装，1 表示重装节点]

private_key=$1
clear=$2

og_dir=$HOME/0g_dir
run_node_sh=$og_dir/run_0g_storage_node.sh

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
    sudo systemctl stop 0g_storage_node
    rm -rf /lib/systemd/system/0g_storage_node.service
    rm -rf $og_dir/0g-storage-node
fi

if [ -f $run_node_sh ]; then
    echo "已部署 0g 服务，只修改秘钥，重启服务"
    echo "进入目录：$og_dir/0g-storage-node/run"
    cd $og_dir/0g-storage-node/run
    sed -i "s/miner_key = .*/miner_key = \"$private_key\"/" config.toml
    sudo systemctl restart 0g_storage_node
    echo "成功重启"
    exit
fi

mkdir -p $og_dir

sudo apt-get update
sudo apt-get install clang cmake build-essential git screen cargo -y

# 安装go
go_version=1.22.2 # 设定go版本号
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_go_version.sh | bash -s -- $go_version
go_dir=/usr/local/go_${go_version}
export PATH=$PATH:${go_dir}/go/bin:$HOME/go/bin # 将go的目录临时添加到环境变量中

# 下载源码，编译源码
cd $og_dir
git clone -b v0.2.0 https://github.com/0glabs/0g-storage-node.git
cd 0g-storage-node
git submodule update --init
cargo build --release

# 配置私钥与其他配置数据
cd run
sed -i "s/miner_key = .*/miner_key = \"$private_key\"/" config.toml
sed -i 's|blockchain_rpc_endpoint = "https://rpc-testnet.0g.ai"|blockchain_rpc_endpoint = "https://evm-rpc-0gchain.dadunode.com"|g' config.toml
sed -i 's/log_sync_start_block_number = 80981/log_sync_start_block_number = 223989/' config.toml

# 配置运行文件
cd $og_dir
cat >$run_node_sh <<EOF
export PATH=\$PATH:${go_dir}/go/bin:$HOME/go/bin # 将go的目录临时添加到环境变量中
cd $og_dir
cd 0g-storage-node/run
../target/release/zgs_node --config config.toml
EOF

# 写入服务
sudo tee /lib/systemd/system/0g_storage_node.service >/dev/null <<EOF
[Unit]
Description=0g storage Service

[Service]  
CPUQuota=100%
User=root
Type=simple
WorkingDirectory=$og_dir
ExecStart=/usr/bin/bash $run_node_sh
Restart=on-abort
StandardOutput=syslog
StandardError=syslog
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd 并启用并启动服务
sudo systemctl daemon-reload
sudo systemctl enable 0g_storage_node
sudo systemctl restart 0g_storage_node
sudo systemctl status 0g_storage_node
# sudo systemctl stop initiad
