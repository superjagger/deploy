#!/bin/bash

source $HOME/.bash_profile

# 系统：Debian
# docker 安装脚本，执行: curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_docker.sh | bash

if which docker >/dev/null 2>&1; then
    echo "Docker 已经安装"
    systemctl start docker
else
    echo "Docker 未安装"

    source /etc/os-release
    echo "${ID} 部署docker"
    if [ "${ID}" = "ubuntu" ]; then
        for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

        echo "添加 Docker GPG key "
        # Add Docker's official GPG key:
        sudo apt-get update
        sudo apt-get install ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        # Add the repository to Apt sources:
        echo "添加 Docker 源 "
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
            sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        echo "更新  apt-get"
        sudo apt-get update

        # 安装
        echo "安装 Docker"
        sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        echo "Docker 成功安装"
    elif [ "${ID}" = "debian" ]; then

        echo "添加 Docker GPG key "
        # Add Docker's official GPG key:
        sudo apt-get update
        sudo apt-get install ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        echo "添加 Docker 源 "
        # Add the repository to Apt sources:
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
            sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        echo "更新 apt-get"
        sudo apt-get update

        echo "安装 Docker"
        # 安装
        sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        echo "Docker 成功安装"
    else
        echo "${ID} 系统未编写部署Docker代码"
        exit
    fi
fi
