#!/bin/bash

# curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/update_quili_2.0.sh | bash

# 文件地址
quili_dir=$HOME/quili_dir
run_node_sh=$quili_dir/run_ceremonyclient_node.sh
service_name=ceremonyclient

# 更新dns
echo "更新dns"
sh -c 'echo "nameserver 8.8.8.8\nnameserver 8.8.4.4" > /etc/resolv.conf'

# 安装go
go_version=1.20.14
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_go_version.sh | bash -s -- $go_version
go_dir=/usr/local/go_${go_version}
export PATH=$PATH:${go_dir}/go/bin:$HOME/go/bin

# 下载最新分支
#cd $quili_dir
#echo "备份原有文件"
#mv ceremonyclient ceremonyclient_$(date +"%Y%m%d_%H%M%S") 
#git clone -b v1.4.20-p1 https://github.com/QuilibriumNetwork/ceremonyclient.git

#手动下载更新quil node二进制文件
cd $quili_dir/ceremonyclient/node/
RELEASE_FILES_URL="https://releases.quilibrium.com/release"
OS_ARCH=linux-amd64
RELEASE_FILES=$(curl -s $RELEASE_FILES_URL | grep -oE "node-[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+-${OS_ARCH}(\.dgst)?(\.sig\.[0-9]+)?")
for file in $RELEASE_FILES; do
    wget "https://releases.quilibrium.com/$file"
done
chmod +x node-2*


#手动下载更新quil qclient二进制文件
cd $quili_dir/ceremonyclient/node/
RELEASE_FILES_URL="https://releases.quilibrium.com/qclient-release"
OS_ARCH=linux-amd64
RELEASE_FILES=$(curl -s $RELEASE_FILES_URL | grep -oE "qclient-[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+-${OS_ARCH}(\.dgst)?(\.sig\.[0-9]+)?")
for file in $RELEASE_FILES; do
    wget "https://releases.quilibrium.com/$file"
done
chmod +x qclient-2*

#查询本机的Effective seniority score
# cd $quili_dir/ceremonyclient/node/
# echo "查询本机的Effective seniority score"
# ./qclient-2.0.0.2-linux-amd64 config prover merge --dry-run .config/ .config/

# 编写节点启动脚本
cat >$run_node_sh <<EOF
go_dir=/usr/local/go_${go_version}
export PATH=\$PATH:\${go_dir}/go/bin:\$HOME/go/bin
cd $quili_dir/ceremonyclient/node
./node-2.0.0.7-linux-amd64
EOF

sudo systemctl daemon-reload
sudo systemctl enable ceremonyclient
sudo systemctl restart ceremonyclient
sudo systemctl status ceremonyclient

