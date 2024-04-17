#!/bin/bash

# 停止ore挖矿进程

# 杀死死循环进程
ps -ef | grep 'bash -c while' | grep -v grep | awk '{print $2}' | xargs kill -9
# 杀死ore进程
ps -ef | grep 'ore --rpc' | grep -v grep | awk '{print $2}' | xargs kill -9
