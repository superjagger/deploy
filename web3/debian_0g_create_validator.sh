#!/bin/bash

# 系统: Debian
# 项目: 0g
# 备注: 创建验证者，必须领过水的，同时区块高度能够查到领水钱包，不然无法创建验证者
# 执行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/debian_0g_create_validator.sh | bash -s -- \"服务器ip\" \"服务器密码\" \"钱包地址\" \"钱包秘钥\" \"助记词\"

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


# 下载 exp 安装 导入助记词脚本
curl -O https://raw.githubusercontent.com/superjagger/deploy/main/web3/debian_0g_recover_mnemonic.exp

# 使用导入助记词
expect debian_0g_recover_mnemonic.exp "${hostname}" "${password}" "${address}" "${private_key}" "${mnemonic}"
