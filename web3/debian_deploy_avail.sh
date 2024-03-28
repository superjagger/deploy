#!/bin/bash

# 系统：Debian
# docker 安装脚本，执行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/debian_deploy_avail.sh | bash

echo "----------------------------- 安装开始 -----------------------------"

# 删除原有节点
sudo systemctl stop availd
sudo systemctl disable availd

# 安装必要的依赖项
apt update -y
apt install -y curl make clang pkg-config libssl-dev build-essential

# 设置安装目录和发布 URL
INSTALL_DIR="${HOME}/avail"
RELEASE_URL="https://github.com/availproject/avail-light/releases/download/v1.7.9/avail-light-linux-amd64.tar.gz"

identity_file=/root/avail/identity.toml

# 创建安装目录并进入
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# 下载并解压发布包
wget "$RELEASE_URL" >/dev/null 2>&1
tar -xvzf avail-light-linux-amd64.tar.gz >/dev/null 2>&1
rm avail-light-linux-amd64.tar.gz
mv avail-light-linux-amd64 avail-light

# 配置 systemd 服务文件
tee /etc/systemd/system/availd.service >/dev/null <<EOF
[Unit]
Description=Avail Light Client
After=network.target
StartLimitIntervalSec=0
[Service]
User=root
ExecStart=/root/avail/avail-light --network goldberg --identity ${identity_file}
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
