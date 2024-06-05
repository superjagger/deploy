#!/bin/bash

# quili 节点部署脚本
# 部署命令行： curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/deploy_quili.sh | bash -s --
# 备份原有数据重新部署命令行： curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/deploy_quili.sh | bash -s -- 1

quili_dir=$HOME/quili_dir
run_node_sh=$quili_dir/run_ceremonyclient_node.sh
service_name=ceremonyclient

# 删除环境变量中的go配置
sed -i '/\/usr\/local\/go\/bin/d' ~/.bash_profile

if [ "$1" == "1" ]; then
    echo "备份原有节点重新部署，如果不想请及时终止脚本"
    sleep 2
    echo "3"
    sleep 2
    echo "2"
    sleep 2
    echo "1"
    sudo systemctl stop ceremonyclient
    rm -rf /lib/systemd/system/ceremonyclient.service
    sudo systemctl daemon-reload
    mv $quili_dir/ceremonyclient $quili_dir/ceremonyclient_bak_$(date +%s)
    rm -rf $run_node_sh
    echo "原有数据已备份"
fi

# 安装go
go_version=1.20.14
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_go_version.sh | bash -s -- $go_version
go_dir=/usr/local/go_${go_version}
export PATH=$PATH:${go_dir}/go/bin:$HOME/go/bin

if [ -f $run_node_sh ]; then
    echo "已部署"
    # 判断服务是否运行
    output=$(systemctl is-active ${service_name})
    # 判断输出是否为 "active"，从而确定服务是否启用
    if [ "$output" = "active" ]; then
        echo "${service_name} 服务已启用"
    else
        echo "${service_name} 服务没有启用，重启服务"
        # 进入ceremonyclient/node目录
        cd $quili_dir
        sudo systemctl start ceremonyclient
        sudo systemctl status ceremonyclient
        echo "成功重启"
    fi
    sleep 5
    journalctl -u ceremonyclient -n 10 --no-pager
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
sudo apt install git ufw bison screen binutils gcc make bsdmainutils cpulimit gawk -y

mkdir -p $quili_dir
cd $quili_dir

# 克隆仓库，切换分支
git clone https://github.com/a3165458/ceremonyclient.git
cd ceremonyclient/node 
git switch release

# 进入ceremonyclient/node目录
cd $quili_dir

# 编写节点启动脚本
cat >$run_node_sh <<EOF
go_dir=/usr/local/go_${go_version}
export PATH=\$PATH:\${go_dir}/go/bin:\$HOME/go/bin
cd $quili_dir/ceremonyclient/node
/usr/bin/bash release_autorun.sh
EOF

# 写入服务
sudo cat >/lib/systemd/system/${service_name}.service <<EOF
[Unit]
Description=${service_name} Service

[Service]  
CPUQuota=200%
User=root
Type=simple
Restart=always
RestartSec=5S
WorkingDirectory=${quili_dir}
Environment=GOEXPERIMENT=arenas
ExecStart=/usr/bin/bash $run_node_sh

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

sleep 5
journalctl -u ceremonyclient -n 10 --no-pager
