#!/bin/bash

# 系统: Debian
# 项目: 0g
# 备注: 创建验证者，必须领过水的，同时区块高度能够查到领水钱包，不然无法创建验证者
# 执行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/debian_0g_create_validator.sh | bash -s -- "钱包地址" "钱包秘钥" "助记词"

address=$1
private_key=$2
mnemonic=$3
if which evmosd > /dev/null 2>&1; then
    echo "evmosd 已经安装"
else
    echo "evmosd 未安装"
    curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/debian_deploy_0g.sh | bash -s -- "${address}" "BwZpAouIfwNWkzw"
fi


# 下载 exp 安装 导入助记词脚本
curl -O https://raw.githubusercontent.com/superjagger/deploy/main/web3/debian_0g_recover_mnemonic.exp

# 使用导入助记词
expect debian_0g_recover_mnemonic.exp "${address}" "${private_key}" "${mnemonic}"
