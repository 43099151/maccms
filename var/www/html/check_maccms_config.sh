#!/bin/sh

# 检查并修复 MacCMS 配置的脚本
# 主要处理后台地址问题

CONFIG_FILE="/var/www/html/maccms/application/database.php"
CONFIG_FILE_COMMON="/var/www/html/maccms/application/common.php"
CONFIG_FILE_ROUTE="/var/www/html/maccms/application/route.php"

echo "正在检查 MacCMS 配置文件..."

# 1. 检查数据库配置
if [ -f "$CONFIG_FILE" ]; then
  echo "找到数据库配置文件: $CONFIG_FILE"
else
  echo "错误: 找不到数据库配置文件: $CONFIG_FILE"
fi

# 2. 检查路由配置
if [ -f "$CONFIG_FILE_ROUTE" ]; then
  echo "找到路由配置文件: $CONFIG_FILE_ROUTE"
  echo "检查路由配置..."
  
  # 检查admin入口是否正确配置
  if grep -q "admin/index/index" "$CONFIG_FILE_ROUTE"; then
    echo "admin 路由配置正常"
  else
    echo "需要检查 admin 路由配置"
  fi
else
  echo "错误: 找不到路由配置文件: $CONFIG_FILE_ROUTE"
fi

# 3. 创建自定义路由配置解决方案
CUSTOM_ROUTE="/var/www/html/maccms/route/route.php"
mkdir -p /var/www/html/maccms/route

cat > "$CUSTOM_ROUTE" << EOF
<?php
// 自定义路由配置

// 后台登录页面的路由修复
use think\\Route;

// 为后台添加直接访问路由
Route::rule('ganzi.php', 'admin/index/index');
Route::rule('ganzi.php/admin/login', 'admin/index/login');
Route::rule('ganzi.php/admin/index/login', 'admin/index/login');
Route::rule('ganzi.php/admin/index/index', 'admin/index/index');

// 返回默认路由配置
return [];
EOF

echo "已创建自定义路由配置: $CUSTOM_ROUTE"

# 4. 修正目录权限
chown -R www-data:www-data /var/www/html/maccms
chmod -R 755 /var/www/html/maccms
chmod -R 777 /var/www/html/maccms/runtime

echo "已修正目录权限"
echo "配置检查完成，请重启服务以应用更改" 
