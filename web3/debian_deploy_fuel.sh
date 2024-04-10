#!/bin/bash

# 系统：Debian
# docker 安装脚本，执行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/debian_deploy_fuel.sh | bash -s -- "节点名称" "私钥" "Ethereum Sepolia RPC连接"

# 节点名称
NODE_NAME=$1
# 私钥，就是之前生成钱包的私钥
P2P_SECRET=$2
# infura网站(https://www.infura.io/zh)添加一个，Ethereum Sepolia 获取RPC连接，之前添加的样例: https://app.infura.io/key/8c27017934ec4bbc814ec122f22fe03e/active-endpoints
ETH_RPC_ENDPOINT=$3

if [ -z "$NODE_NAME" ] || [ -z "$P2P_SECRET" ] || [ -z "$ETH_RPC_ENDPOINT" ]; then
    echo "缺少参数"
    exit 1
fi

# 暂停原有节点
sudo systemctl stop fuel
sudo systemctl disable fuel
rm /etc/systemd/system/fuel.service

# fuel执行文件存储位置
fuel_folder=$HOME/fuel_folder

mkdir -p ${fuel_folder}

cd $fuel_folder

# 重新引用环境变量
source /root/.bash_profile

# 安装fuel-core
if ! command -v fuel-core &>/dev/null; then
    echo "fuel-core: 未安装"
    # 基础包安装
    apt-get install -y cmake pkg-config build-essential git clang libclang-dev expect

    # rust安装
    curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_rust.sh | bash

    # 下载 exp 安装 fuel 脚本
    curl -O https://raw.githubusercontent.com/superjagger/deploy/main/web3/deploy_fuel.exp

    # 使用exp安装fuel
    expect deploy_fuel.exp

    echo "export PATH="$HOME/.fuelup/bin:$PATH"" >>/root/.bash_profile

    # 重新引用环境变量
    source /root/.bash_profile
    rm -rf deploy_fuel.exp
else
    echo "fuel-core: 已安装"
fi


# 要持久运行本地节点，您必须配置一个chainConfig.json文件。这里直接下载官方配置版本: beta-5
curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/FuelLabs/fuel-core/v0.22.0/deployment/scripts/chainspec/beta_chainspec.json -sSf >${fuel_folder}/chainConfig.json

fuel_run_sh=$fuel_folder/fuel_run.sh

rm -rf ${fuel_run_sh}

# 添加运行脚本
cat >${fuel_run_sh} <<EOF
fuel-core run \
    --service-name ${NODE_NAME} \
    --keypair ${P2P_SECRET} \
    --relayer ${ETH_RPC_ENDPOINT}\
    --ip 0.0.0.0 --port 4000 --peering-port 30333 \
    --db-path  ${HOME}/.fuel_beta5 \
    --chain ${fuel_folder}/chainConfig.json \
    --utxo-validation --poa-instant false --enable-p2p \
    --min-gas-price 1 --max-block-size 18874368  --max-transmit-size 18874368 \
    --reserved-nodes /dns4/p2p-beta-5.fuel.network/tcp/30333/p2p/16Uiu2HAmSMqLSibvGCvg8EFLrpnmrXw1GZ2ADX3U2c9ttQSvFtZX,/dns4/p2p-beta-5.fuel.network/tcp/30334/p2p/16Uiu2HAmVUHZ3Yimoh4fBbFqAb3AC4QR1cyo8bUF4qyi8eiUjpVP \
    --sync-header-batch-size 100 \
    --enable-relayer \
    --relayer-v2-listening-contracts 0x557c5cE22F877d975C2cB13D0a961a182d740fD5 \
    --relayer-da-deploy-height 4867877 \
    --relayer-log-page-size 2000
EOF

# 配置 systemd 服务文件
tee /etc/systemd/system/fuel.service >/dev/null <<EOF
[Unit]
Description=Fuel Client
After=network.target
StartLimitIntervalSec=0
[Service]
User=root
ExecStart=bash ${fuel_run_sh}
Restart=always
RestartSec=120
[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd 并启用并启动服务
sudo systemctl daemon-reload
sudo systemctl enable fuel
sudo systemctl start fuel.service
