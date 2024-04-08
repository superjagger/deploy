#!/bin/bash

# 系统：Debian
# docker 安装脚本，执行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/debian_deploy_fuel.sh | bash

# 重新引用环境变量
source /root/.bash_profile

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
  
  echo "export PATH="$HOME/.fuelup/bin:$PATH"" >> /root/.bash_profile
  
  # 重新引用环境变量
  source /root/.bash_profile
  rm -rf deploy_fuel.exp
else
  echo "fuel-core: 已安装"
fi
