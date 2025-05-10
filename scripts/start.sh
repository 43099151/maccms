#!/bin/bash
set -e

# 初始化 MySQL 数据目录
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql > /dev/null
    /etc/init.d/mysql start > /dev/null
    mysql -u root -e "CREATE DATABASE IF NOT EXISTS maccms; CREATE USER IF NOT EXISTS 'maccms'@'localhost' IDENTIFIED BY 'maccms123'; GRANT ALL PRIVILEGES ON maccms.* TO 'maccms'@'localhost'; FLUSH PRIVILEGES;" > /dev/null
else
    /etc/init.d/mysql start > /dev/null
fi

# 启动 Apache
/usr/sbin/apache2ctl -D FOREGROUND
