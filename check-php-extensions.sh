#!/bin/sh

# 在容器内运行此脚本以检查 PHP 扩展安装情况
# 使用方法: docker exec -it <container_name> /var/www/html/check-php-extensions.sh

echo "== PHP 版本 =="
php -v
echo ""

echo "== 已安装的 PHP 扩展 =="
php -m
echo ""

echo "== 检查特定扩展 =="
extensions="mysqli pdo_mysql gd mbstring zip exif bcmath fileinfo soap intl opcache"

for ext in $extensions; do
  if php -m | grep -q "$ext"; then
    echo "✅ $ext 已安装"
  else
    echo "❌ $ext 未安装"
  fi
done

echo ""
echo "== PHP-FPM 状态 =="
if ps aux | grep php-fpm | grep -v grep > /dev/null; then
  echo "✅ PHP-FPM 正在运行"
else
  echo "❌ PHP-FPM 未运行"
fi

echo ""
echo "== Nginx 状态 =="
if ps aux | grep nginx | grep -v grep > /dev/null; then
  echo "✅ Nginx 正在运行"
else
  echo "❌ Nginx 未运行"
fi

echo ""
echo "== 检查 PHP 配置 =="
php -i | grep "Configuration File"
php -i | grep "memory_limit"
php -i | grep "upload_max_filesize"
php -i | grep "post_max_size"
php -i | grep "date.timezone"

echo ""
echo "== 检查 Nginx 配置 =="
nginx -t 2>&1 
