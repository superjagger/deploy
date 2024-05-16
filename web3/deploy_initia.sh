#!/bin/bash

# initia 节点部署脚本
# 部署命令行： curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/web3/deploy_initia.sh | bash

# 关闭防火墙
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/stop_firewall.sh | bash

# 创建文件目录
initia_dir=$HOME/initia_dir
mkdir -p $initia_dir
# 启动脚本
run_node_sh=$initia_dir/run_initia_node.sh

# if [ -f $run_node_sh ]; then
#     echo "已部署 initiad ，只进行服务重启"
#     sudo systemctl restart initiad
#     echo "成功重启"
#     exit
# fi
echo "开始部署 initiad"

# 清理环境变量中的go版本
go_version=1.22.2 # 设定go版本号
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_go_version.sh | bash -s -- $go_version
go_dir=/usr/local/go_${go_version}
export PATH=$PATH:${go_dir}/go/bin:$HOME/go/bin # 将go的目录临时添加到环境变量中，只保存当前命令行窗口

# 更新和安装必要的软件
apt-get update && apt upgrade -y
apt-get install -y curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev lz4 snapd

cd $initia_dir

# 安装所有二进制文件
git clone https://github.com/initia-labs/initia
cd initia
git checkout v0.2.12
make install
initiad version

# 配置initiad
initiad init "Moniker" --chain-id initiation-1
initiad config set client chain-id initiation-1

# 获取初始文件和地址簿
wget -O $HOME/.initia/config/genesis.json https://initia.s3.ap-southeast-1.amazonaws.com/initiation-1/genesis.json
wget -O $HOME/.initia/config/addrbook.json https://rpc-initia-testnet.trusted-point.com/addrbook.json
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.15uinit,0.01uusdc\"|" $HOME/.initia/config/app.toml

# 配置节点
PEERS="e634bbdc8a1fee53b9c2abc779c653c21adb7496@168.119.10.134:26995,d6875c002ff3dacacbb1c971169f1e2c1193119b@65.109.139.2:26656,bc64e8794465dd46399bf6f49a564098e09b0843@164.92.96.212:26656,058e9cc6d252a5070c13815e7cd5f30cf493c52f@5.161.227.226:26656,cdedfbed5139d32412858fa2aa2cee9566a91dd8@89.117.58.234:26656,aed2c793c683e555cff07bc44d084b1e4b76d42e@171.250.165.103:10256,68f0ada2c2c120371037a2e65fbf2f9337f68918@75.119.141.44:15656,2129f6296413e134d94c5a0b98905cc4108860f8@194.5.157.3:26656,da60b9e1d8f8618307de3ef0d9a61eac6bf7d634@45.144.29.157:26656,a1b7fbda148b4a437b63584018a2a88ebe45f25f@86.48.3.66:26656,703edda35d84e48b7b0d9158dee9826180b4d122@37.27.80.245:26656,7292af244f9c87937a01d8e5bcd090449d4404f0@62.171.176.118:11856,268da5b10276ea13c4d839fe387249428b407f3d@148.113.8.196:24056,3a6e62cd90f6575bbcbd508a177b66aa478bfc69@45.76.176.66:26656,095f952cde7cc7991a877837ed84a009bb3b098e@84.46.247.107:12656,ede11cab565486fb268a5b28a22da604b2e455d3@95.216.155.52:26656,a6b0dea0d790beb9c9127323fc191beed2c6ccaa@185.137.122.227:11856,c7c80f0f5b6dfe4837abd6a7eab4c8342e5c2a95@65.109.115.56:11856,c363b364f61ff8d4a2e063e0223bdfcb8c4d0831@213.199.48.49:27656,b9e22f6799c5867879a4ff5d9f290722085ad199@84.247.189.90:26656,f5d973568fec14272c8b3ced0cb74277ff5866fa@62.171.131.124:26656,81437ded1cfe775274ec44dc7a822a7be5dc406f@118.71.116.24:26656,6cec2868ca6b7fa0991267cc91789bfc32a7ca7a@65.109.93.124:26856,70f7dc74d3b6afa12b988d61707229e8e191d9a2@213.246.45.16:55656,3a3a0bdec8de5993ddb3a7c3e7185d06c62d8a99@62.171.166.114:26656,7717ea3ed671e0da76ba35a05a9c7c24c8176f83@89.58.36.209:2656,cf56d4b46349a9bc0bd88eb3b67590a124a3d092@139.180.130.182:26656,9878d322ad5f18696a92a620b3451426134f46e6@62.169.25.68:11856,cd023377468374e7482dd762db2977c6db44e10f@84.247.166.63:26656,d1d43cc7c7aef715957289fd96a114ecaa7ba756@65.21.198.100:24010,e01e82e12beeb44b7ff3e98b1e62f9b976356e84@206.221.176.90:29656,ade303649081d98ab8ab0287530afee607d5b95b@104.248.195.112:26656,3c3c586ea54307a6b8dca556c1a1eda5d8fe04f6@136.243.104.103:24056,182b7f7ec60961b365808aece3837b6f1786a2b3@95.217.13.48:26656,4faecd8b45561ed0bbab9e5362045b4e7edaaa11@128.140.89.194:11856,0b7dbbbf7ae007daafe3c49c142fce5dcc9a1c55@94.72.125.122:26656,de7f52f477fd8953db29f0f8aae09f717ed590fb@94.72.101.240:26656,9b81767b5d1bec4a50fbe24984c1958ac6b2a4cb@158.220.108.166:12656,54380248083ddcb8b0907cc6607a10bacce2c32f@118.71.116.24:26656,7517e2df33c5356aad057e6c3033cdb2e3e4b544@94.72.108.222:26656,93165d63303c5632b060a8dcfc8a440fd001c0c8@68.183.183.234:26656,553929612a342dcc988d98ad2934f52cc47a51e4@58.187.137.210:32656,e94719f60d03fd1864551ad07746284083dd1bb9@161.97.131.194:26656,0c9fa03479edf7093241305be1f6b5a361039c28@45.85.147.82:11856,153f0d20405f7343b7b0c93cbed8c3957379416f@57.128.63.126:26656,b922ce9a6945df4198211eabd8b047dacc5de81e@65.108.238.215:29056,eab329a812987efda7b6b015b06554390194634f@109.205.178.231:27656,a848ebed4c4a2e235e838640abd849d58eafd2e3@75.119.154.225:11856,666ed0538062095efe09c9447c4fc700d275ff95@65.21.105.12:11856,289626099b5ee210bbb5b4141697c98f726b2293@207.180.196.56:26656,fd944910711f27415fd308ec8d19ec624a5fa4a0@159.69.112.49:26656,2c6ae886df41b08b6361de953ad44c6f574afb05@51.178.92.69:12656,b5d5226ac957b8b384644e0aa2736be4b40f806c@46.38.232.86:14656,84868ec9449ca2a9942b3af1b2ff01bed071a45b@95.216.136.240:26656,f5bd4b6fdbcc0d9fbf83b067e362123dd8cf1dcd@152.42.191.106:26556,d7a743ecacaadf9be29d3da733d5c90cff7cf3f5@154.12.227.137:26656,1967e0c2e99401c49fbed2c7f1aa224a675e09a2@142.132.156.99:31056,2850a114bcaf0d388bf5b62165fe945e57fd44a5@167.86.80.169:26656"
sed -i \
    -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" \
    "$HOME/.initia/config/config.toml"


# 配置端口
node_address="tcp://localhost:53457"
sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:53458\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:53457\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:53460\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:53456\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":53466\"%" $HOME/.initia/config/config.toml
sed -i -e "s%^address = \"tcp://localhost:1317\"%address = \"tcp://0.0.0.0:53417\"%; s%^address = \":8080\"%address = \":53480\"%; s%^address = \"localhost:9090\"%address = \"0.0.0.0:53490\"%; s%^address = \"localhost:9091\"%address = \"0.0.0.0:53491\"%; s%:8545%:53445%; s%:8546%:53446%; s%:6065%:53465%" $HOME/.initia/config/app.toml

export initiad_RPC_PORT=$node_address

cd $initia_dir
slinky_dir=$initia_dir/slinky
# 配置预言机
git clone https://github.com/skip-mev/slinky.git
cd $slinky_dir

# checkout proper version
git checkout v0.4.3

make build

# 配置预言机启用
sed -i -e 's/^enabled = "false"/enabled = "true"/' \
    -e 's/^oracle_address = ""/oracle_address = "127.0.0.1:8080"/' \
    -e 's/^client_timeout = "2s"/client_timeout = "500ms"/' \
    -e 's/^metrics_enabled = "false"/metrics_enabled = "false"/' $HOME/.initia/config/app.toml

# 配置快照
sudo apt install lz4 -y
wget -O initia_120971.tar.lz4 https://snapshots.polkachu.com/testnet-snapshots/initia/initia_120971.tar.lz4 --inet4-only
initiad tendermint unsafe-reset-all --home $HOME/.initia --keep-addr-book
lz4 -c -d initia_120971.tar.lz4 | tar -x -C $HOME/.initia


cd $initia_dir
# 编写节点启动脚本
cat >$run_node_sh <<EOF
go_dir=/usr/local/go_${go_version}
export PATH=\$PATH:\${go_dir}/go/bin:\$HOME/go/bin
source $HOME/.bash_profile
# 启动节点
initiad start
EOF

# 写入服务
sudo tee /lib/systemd/system/initiad.service >/dev/null <<EOF
[Unit]
Description=initiad Service

[Service]  
CPUQuota=100%
User=root
Type=simple
WorkingDirectory=${initia_dir}
ExecStart=/usr/bin/bash run_initia_node.sh
Restart=on-abort
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=initiad
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd 并启用并启动服务
sudo systemctl daemon-reload
sudo systemctl enable initiad
sudo systemctl restart initiad
sudo systemctl status initiad
# sudo systemctl stop initiad
# journalctl -u initiad -f -n 10

