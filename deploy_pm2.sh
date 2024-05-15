#!/bin/bash
# 执行命令: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_pm2.sh | bash

# 安装node
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_node.sh | bash

source $HOME/.bash_profile

if which pm2 >/dev/null 2>&1; then
    echo "PM2 已安装"
else
    echo "PM2 未安装"
    npm install pm2@latest -g
fi
