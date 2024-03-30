#!/bin/bash

source $HOME/.bash_profile

# node 安装脚本，执行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_node.sh | bash

if ! command -v node &>/dev/null; then
    echo "node 未安装"

    # 安装 Node.js，先安装 NVM
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    # 写入环境变量，永久生效
    echo 'export NVM_DIR="$HOME/.nvm"' >>$HOME/.bash_profile
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >>$HOME/.bash_profile
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >>$HOME/.bash_profile
    source $HOME/.bash_profile
    # 安装 Node.js 20
    nvm install 20
    # 查看版本
    node -v
    npm -v
    
else
    echo "node 已经安装"
fi
