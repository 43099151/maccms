#---------------------------------------------------------------------
# 阶段 1: cloudsaver_ref (无变化)
#---------------------------------------------------------------------
FROM jiangrui1994/cloudsaver:latest AS cloudsaver_ref

#---------------------------------------------------------------------
# 阶段 2: 最终镜像 (基于 Alpine)
#---------------------------------------------------------------------
# 使用与PHP版本对应的Alpine基础镜像
FROM php:7.4.33-apache-alpine

# --- 1. 设置环境变量 (Go相关的环境变量可以保留) ---
ENV TZ=Asia/Shanghai \
    GOPATH=/go \
    GO_VERSION=1.24.4
ENV PATH=/usr/local/go/bin:${GOPATH}/bin:${PATH}

# --- 2. 安装所有系统依赖和工具 (使用 apk) ---
# --no-cache 避免缓存索引，保持镜像小
RUN apk update && apk add --no-cache \
    # PHP 扩展构建依赖 (包名可能略有不同)
    libpng-dev jpeg-dev freetype-dev libzip-dev oniguruma-dev \
    # supervisor 和其他工具
    supervisor openssh sudo curl wget git ca-certificates cron tmux ufw lsof \
    net-tools vim nano less grep findutils tar gzip bzip2 unzip procps iproute2 \
    ping dnsutils sshpass inotify-tools \
    # Python 和 Node.js
    python3 py3-pip nodejs npm \
    # Java (运行CloudSaver) - openjdk8 在社区仓库
    openjdk8-jre \
    # Go 语言
    go

# --- 3. 安装 PHP 扩展 (指令不变) ---
RUN docker-php-ext-install mysqli pdo_mysql gd mbstring zip

# --- 4. 安装 Python 依赖 (指令不变) ---
RUN pip install --no-cache-dir \
    requests PyYAML apscheduler beautifulsoup4 lxml \
    Flask Flask-APScheduler Flask-Login anytree colorlog treelib

# --- 5. 复制和配置应用程序 (指令不变) ---
COPY --from=cloudsaver_ref /app /opt/cloudsaver
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY docker-entrypoint.sh /

# --- 6. 设置目录和权限 (指令不变，但Alpine中用户是apache) ---
# 注意：在Alpine的php-apache镜像中，用户和组是 apache:apache 而不是 www-data:www-data
RUN mkdir -p /opt/cloudsaver/data /opt/cloudsaver/config && \
    chown -R apache:apache /opt/cloudsaver && \
    chmod -R 775 /opt/cloudsaver

RUN mkdir -p /var/www/html/maccms/runtime && \
    chown -R apache:apache /var/www/html && \
    chmod -R 775 /var/www/html && \
    chmod -R 777 /var/www/html/maccms/runtime && \
    sed -i 's|/var/www/html|/var/www/html/maccms|g' /etc/apache2/httpd.conf

RUN mkdir -p /var/run/sshd && chmod +x /docker-entrypoint.sh

# --- 7. 暴露端口和定义启动命令 (指令不变) ---
EXPOSE 80
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
