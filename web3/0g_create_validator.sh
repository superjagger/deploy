#!/bin/bash

# 系统: Debian
# 项目: 0g
# 备注: 创建验证者，必须领过水的，同时区块高度能够查到领水钱包，不然无法创建验证者
# 执行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/0g_create_validator.sh | bash -s -- "IP" "服务器密码" "钱包地址" "钱包秘钥" "助记词"

source $HOME/.bash_profile

curl -O https://raw.githubusercontent.com/superjagger/deploy/main/escape_for_expect.sh && source escape_for_expect.sh && rm ./escape_for_expect.sh
echo $2
ip=$1
password=$(escape_for_expect $2)
address=$3
private_key=$4
mnemonic=$5
if which evmosd > /dev/null 2>&1; then
    echo "evmosd 已经安装"
else
    echo "evmosd 未安装"
    curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/deploy_0g.sh | bash -s -- "${address}" "BwZpAouIfwNWkzw"
fi

sudo apt-get install -y expect

# 下载 exp 安装 导入助记词脚本
curl -O https://raw.githubusercontent.com/superjagger/deploy/main/web3/0g_create_validator.exp

# 引用函数: output=$(escape_for_expect $input)

echo "转以后密码: ${password}"
# 使用导入助记词
expect 0g_create_validator.exp "${ip}" "${password}" "${address}" "${private_key}" "${mnemonic}"

rm 0g_create_validator.exp
