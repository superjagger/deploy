#!/bin/bash
# curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/prometheus/deploy_process_exporter.sh | bash -s -- 

prometheus_dir=$HOME/prometheus
process_dir=$prometheus_dir/process-exporter
mkdir -p $prometheus_dir
mkdir -p $process_dir

# 安装docker
curl -sSL https://raw.githubusercontent.com/superjagger/deploy/main/deploy_docker.sh | bash

cd $process_dir
cat >$process_dir/config.yml<<EOF
process_names:
  - name: "{{.Matches}}"
    cmdline:
    - '0gchaind'
  - name: "{{.Matches}}"
    cmdline:
    - 'zgs_node'
  - name: "{{.Matches}}"
    cmdline:
    - 'artelad'
EOF
docker run -d -it -p 9256:9256 --privileged -v /proc:/host/proc -v $process_dir:/config --name=process-exporter --restart=always ncabatoff/process-exporter --procfs /host/proc -config.path /config/config.yml
docker restart
