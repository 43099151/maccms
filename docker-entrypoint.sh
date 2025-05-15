#!/bin/bash
set -e

# 启动cron服务
service cron start

# 启动sshd服务
service ssh start

# 启动supervisor
exec "$@"
