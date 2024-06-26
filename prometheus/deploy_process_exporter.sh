#!/bin/bash
# curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/prometheus/deploy_process_exporter.sh | bash -s -- "进程1" "进程2" "进程N"

prometheus_dir=$HOME/prometheus
process_dir=$prometheus_dir/process-exporter
mkdir -p $prometheus_dir
mkdir -p $process_dir

# 安装docker
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_docker.sh | bash

cd $process_dir
cat >$process_dir/config.yml<<EOF
process_names:
EOF


# 遍历所有的命令行参数作为要监听的进程
for arg in "$@"; do  
cat >>$process_dir/config.yml<<EOF
  - name: "{{.Matches}}"
    cmdline:
    - '$arg'
EOF
done

cat $process_dir/config.yml

docker run -d -it -p 9256:9256 --privileged -v /proc:/host/proc -v $process_dir:/config --name=process-exporter --restart=always ncabatoff/process-exporter --procfs /host/proc -config.path /config/config.yml
docker restart process-exporter

echo "结束部署"
