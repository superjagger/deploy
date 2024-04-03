#!/bin/bash

# 系统：Debian
# docker 安装脚本，执行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/debian_deploy_avail.sh | bash

echo "----------------------------- 安装开始 -----------------------------"

# 暂停原有节点
sudo systemctl stop availd
sudo systemctl disable availd
rm /etc/systemd/system/availd.service

# 安装必要的依赖项
apt update -y
apt install -y curl make clang pkg-config libssl-dev build-essential

# 设置安装目录和发布 URL
INSTALL_DIR="${HOME}/avail"
RELEASE_URL="https://github.com/availproject/avail-light/releases/download/v1.7.9/avail-light-linux-amd64.tar.gz"

# 助记词存储路径
identity_file="/root/avail/identity.toml"

# 创建安装目录并进入
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

avail_sh=${INSTALL_DIR}/avail.sh

curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/availproject/availup/main/availup.sh -sSf > ${avail_sh}
run_avail_node="curl -sL1 ${avail_sh} | bash -s -- --identity ${identity_file} --upgrade y"


# 配置 systemd 服务文件
tee /etc/systemd/system/availd.service >/dev/null <<EOF
[Unit]
Description=Avail Light Client
After=network.target
StartLimitIntervalSec=0
[Service]
User=root
ExecStart=${run_avail_node}
Restart=always
RestartSec=120
[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd 并启用并启动服务
sudo systemctl daemon-reload
sudo systemctl enable availd
sudo systemctl start availd.service

# journalctl -u availd | grep address
echo ====================================== 助记词文件：${identity_file} =========================================
cat ${identity_file}
# 完成安装提示
echo ====================================== 安装完成 =========================================
