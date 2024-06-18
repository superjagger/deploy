#!/bin/bash

# 安装docker
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_docker.sh | bash

# 启动服务
docker run -d -it --name nubit --restart=always ubuntu:24.04 bash -c "apt-get update && apt-get install curl -y && curl -sL1 https://nubit.sh | bash"
