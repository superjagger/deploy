#!/bin/bash

# juneo升级到主网
cd ~/juneo_dir/juneogo-docker
docker compose down
git pull
git checkout origin/main ./juneogo/juneogo
git checkout origin/main ./juneogo/.juneogo/plugins/jevm
docker compose up -d juneogo
