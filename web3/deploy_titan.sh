#!/bin/bash

# quili 节点部署脚本
# 部署命令行： curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/deploy_titan.sh | bash -s -- [node_id]

node_id=$1

if [ -z "$node_id" ]; then
    echo "缺少参数: node_id"
    exit
fi

titan_dir=$HOME/titan_dir
mkdir -p $titan_dir

run_node_sh=$titan_dir/run_titan_node.sh
service_name=titan

if [ -f $run_node_sh ]; then
    echo "${service_name} 已部署"
    # 判断服务是否运行
    output=$(systemctl is-active ${service_name})
    # 判断输出是否为 "active"，从而确定服务是否启用
    if [ "$output" = "active" ]; then
        echo "${service_name} 服务已启用"
    else
        echo "${service_name} 服务没有启用，重启服务"
        # 进入ceremonyclient/node目录
        cd $quili_dir
        sudo systemctl start ${service_name}
        echo "成功重启"
    fi

    cd $titan_dir/titan_v0.1.18_linux_amd64
    ./titan-edge bind --hash=${node_id} https://api-test1.container1.titannet.io/api/v2/device/binding
    
    sleep 10
    sudo systemctl status ${service_name}
    journalctl -u ${service_name} -n 10 --no-pager
    exit
fi

cd $titan_dir
wget -c https://github.com/Titannet-dao/titan-node/releases/download/v0.1.18/titan_v0.1.18_linux_amd64.tar.gz
tar -xzf titan_v0.1.18_linux_amd64.tar.gz

# 编辑启动命令
cat >$run_node_sh <<EOF
cd $titan_dir/titan_v0.1.18_linux_amd64
# 启动节点
./titan-edge daemon start --init --url https://test-locator.titannet.io:5000/rpc/v0
EOF

# 写入服务
cat >/lib/systemd/system/${service_name}.service <<EOF
[Unit]
Description=${service_name} Service

[Service]  
CPUQuota=100%
User=root
Type=simple
Restart=always
RestartSec=5S
WorkingDirectory=${titan_dir}
Environment=GOEXPERIMENT=arenas
ExecStart=/usr/bin/bash $run_node_sh
[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd 并启用并启动服务
sudo systemctl daemon-reload
sudo systemctl enable ${service_name}
sudo systemctl restart ${service_name}
# sudo systemctl stop ${service_name}
# journalctl -u ${service_name} -f -n 10

sleep 3
# 修改端口避免端口冲突
sed -i 's/.*#\?.*ListenAddress = .*/  ListenAddress = "0.0.0.0:1888"/' ~/.titanedge/config.toml
# 重启服务
sudo systemctl restart ${service_name}
sudo systemctl status ${service_name}

# 绑定id
sleep 10
cd $titan_dir/titan_v0.1.18_linux_amd64
./titan-edge bind --hash=${node_id} https://api-test1.container1.titannet.io/api/v2/device/binding

# 输出运行日志
sleep 5
journalctl -u ceremonyclient -n 10 --no-pager
