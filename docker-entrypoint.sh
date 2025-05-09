#!/bin/bash

# 初始化 MariaDB 数据库（如首次启动）
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql
fi

# 修复MariaDB权限
chown -R mysql:mysql /var/lib/mysql

# 确保 /run/mysqld 目录存在且权限正确
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

exec "$@"
