#!/bin/bash

# 系统：Debian
# docker 安装脚本，执行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/debian_deploy_avail.sh | bash

echo "----------------------------- 安装开始 -----------------------------"


# 暂停原有节点
sudo systemctl stop availd
sudo systemctl disable availd
rm /etc/systemd/system/availd.service

# 关闭防火墙
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/stop_firewall.sh | bash

# 安装必要的依赖项
apt update -y
apt install -y curl make clang pkg-config libssl-dev build-essential

# 设置安装目录和发布 URL
INSTALL_DIR="${HOME}/avail"

# 助记词存储路径
identity_file="/root/avail/identity.toml"

if [ -n "$1" ]; then  
  echo "使用自定义助记词: $1"
  echo "avail_secret_seed_phrase = '$1'" >${identity_file}
fi


# 创建安装目录并进入
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

avail_sh=${INSTALL_DIR}/avail.sh

curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/availproject/availup/main/availup.sh -sSf > ${avail_sh}
run_avail_node="bash ${avail_sh} --identity ${identity_file} --upgrade y"


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

sleep 5
echo "获取节点信息"
# 初始化变量  
last_ss58_address=""  
last_public_key=""  
  
# 读取日志
log_content=$(journalctl -u availd.service -n 50 | grep "Avail ss58 address")
  
# 使用正则表达式匹配并提取信息  
while [[ $log_content =~ (Avail ss58 address: )([^ ,]*)(.*)(public key: )([a-fA-F0-9]*) ]]; do  
    ss58_address=${BASH_REMATCH[2]}  
    public_key=${BASH_REMATCH[5]}  
  
    # 更新变量为最新匹配的内容  
    last_ss58_address=$ss58_address  
    last_public_key=$public_key  
  
    # 移除已匹配的内容，继续查找剩余内容  
    log_content=${log_content#*${BASH_REMATCH[0]}}  
done  
  
phrase=$(cat identity.toml | grep 'avail_secret_seed_phrase' | sed -n 's/.*avail_secret_seed_phrase = '\''\(.*[^\\]\)'\''.*/\1/p')

# journalctl -u availd | grep address
echo ====================================== 助记词文件：${identity_file} =========================================
echo "${phrase},${last_ss58_address},${public_key}" > ${INSTALL_DIR}/file.csv
cat ${INSTALL_DIR}/file.csv
# 完成安装提示
echo ====================================== 安装完成 =========================================
