#!/bin/bash

# quili 节点部署脚本
# 部署命令行： curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/deploy_quili.sh | bash
# 清除原有数据部署命令行： curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/deploy_quili.sh | bash -s -- 1

quili_dir=$HOME/quili_dir
run_node_sh=$quili_dir/run_ceremonyclient_node.sh

go_version=1.20.14

if [ "$1" == "1" ]; then
    echo "准备清空原有节点重新部署，如果不想请及时终止脚本"
    sleep 2
    echo "3"
    sleep 2
    echo "2"
    sleep 2
    echo "1"
    sudo systemctl stop ceremonyclient
    rm -rf /lib/systemd/system/ceremonyclient.service
    rm -rf $quili_dir/ceremonyclient
    rm -rf run_node_sh
    echo "原有数据已清空"
fi

# 安装go
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_go_version.sh | bash -s -- $go_version
go_dir=/usr/local/go_${go_version}
export PATH=$PATH:${go_dir}/go/bin:$HOME/go/bin

if [ -f $run_node_sh ]; then
    echo "已部署，只进行服务重启"
    # 进入ceremonyclient/node目录
    cd $quili_dir

    # 写入服务
    sudo tee /lib/systemd/system/ceremonyclient.service >/dev/null <<EOF
[Unit]
Description=Ceremony Client GO App Service

[Service]  
CPUQuota=40%
User=root
Type=simple
Restart=always
RestartSec=5S
WorkingDirectory=${quili_dir}
Environment=GOEXPERIMENT=arenas
ExecStart=/usr/bin/bash run_ceremonyclient_node.sh

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    # 编写节点启动脚本
    cat >$run_node_sh <<EOF
go_dir=/usr/local/go_${go_version}
export PATH=\$PATH:\${go_dir}/go/bin:\$HOME/go/bin
cd $quili_dir/ceremonyclient/node
/usr/bin/bash poor_mans_cd.sh
EOF
    sudo systemctl restart ceremonyclient
    exit
fi

if [ -d "/swap" ]; then
    echo "目录 /swap 存在"
else
    echo "目录 /swap 不存在"
    sudo mkdir -p /swap
    sudo fallocate -l 24G /swap/swapfile
    sudo chmod 600 /swap/swapfile
    sudo mkswap /swap/swapfile
    sudo swapon /swap/swapfile
    echo '/swap/swapfile swap swap defaults 0 0' >>/etc/fstab

    # 重新加载sysctl配置以应用更改
    sysctl -p
fi

sudo apt update && sudo apt -y upgrade
sudo apt install git ufw bison screen binutils gcc make bsdmainutils -y

mkdir -p $quili_dir
cd $quili_dir

# 克隆仓库
git clone https://github.com/quilibriumnetwork/ceremonyclient

# 进入ceremonyclient/node目录
cd $quili_dir

# 编写节点启动脚本
cat >$run_node_sh <<EOF
go_dir=/usr/local/go_${go_version}
export PATH=\$PATH:\${go_dir}/go/bin:\$HOME/go/bin
cd $quili_dir/ceremonyclient/node
/usr/bin/bash poor_mans_cd.sh
EOF

# 写入服务
sudo tee /lib/systemd/system/ceremonyclient.service >/dev/null <<EOF
[Unit]
Description=Ceremony Client GO App Service

[Service]  
CPUQuota=40%
User=root
Type=simple
Restart=always
RestartSec=5S
WorkingDirectory=${quili_dir}
Environment=GOEXPERIMENT=arenas
ExecStart=/usr/bin/bash run_ceremonyclient_node.sh

[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd 并启用并启动服务
sudo systemctl daemon-reload
sudo systemctl enable ceremonyclient
sudo systemctl restart ceremonyclient
sudo systemctl status ceremonyclient
# sudo systemctl stop ceremonyclient
# journalctl -u ceremonyclient -f -n 10
