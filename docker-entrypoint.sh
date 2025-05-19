#!/bin/bash

# 由于连接外部数据库，以下本地 MariaDB 初始化步骤已注释掉
# # 初始化 MariaDB 数据库（如首次启动）
# if [ ! -d "/var/lib/mysql/mysql" ]; then
#     mariadb-install-db --user=mysql --datadir=/var/lib/mysql
# fi
# 
# # 修复MariaDB权限
# chown -R mysql:mysql /var/lib/mysql
# 
# # 确保 /run/mysqld 目录存在且权限正确
# mkdir -p /run/mysqld
# chown mysql:mysql /run/mysqld

# 自动同步定时任务文件并重载cron服务
if [ -d /var/www/html/cron ]; then
  cp -f /var/www/html/cron/* /etc/cron.d/ 2>/dev/null || true
  chmod 0644 /etc/cron.d/* 2>/dev/null || true
  service cron reload 2>/dev/null || true
fi

exec "$@"
