#!/bin/bash

# 系统: Debian
# 项目: 0g
# 备注: 创建验证者
# 执行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/debian_deploy_0g.sh | bash -s -- \"节点与钱包名称\"

hostname=$1
password=$2
address=$3
private_key=$4
mnemonic=$5
if which evmosd > /dev/null 2>&1; then
    echo "evmosd 已经安装"
else
    echo "evmosd 未安装"
    sshpass -p "${password}" ssh -n -o StrictHostKeyChecking=no root@${hostname} "curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/debian_deploy_0g.sh | bash -s -- \"${address}\" \"BwZpAouIfwNWkzw\"" >${hostname}.log 2>&1 &
fi
