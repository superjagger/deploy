#!/bin/bash

source $HOME/.bash_profile

# 系统：Debian
# docker 安装脚本，执行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/debian_deploy_docker.sh | bash

if ! command -v docker &>/dev/null; then
    echo "Docker 未安装"
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
        sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    sudo apt-get update

    # 安装
    sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "Docker 成功安装"
else
    echo "Docker 已经安装"
fi
