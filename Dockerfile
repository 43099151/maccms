#---------------------------------------------------------------------
# 阶段 1: cloudsaver_ref
#---------------------------------------------------------------------
FROM jiangrui1994/cloudsaver:latest AS cloudsaver_ref

#---------------------------------------------------------------------
# 阶段 2: 最终镜像 (final_image)
#---------------------------------------------------------------------
FROM php:7.4.33-apache

# --- 1. 设置环境变量 ---
# 设置时区、Go语言环境、Node.js环境
ENV TZ=Asia/Shanghai \
    GOPATH=/go \
    GO_VERSION=1.24.4
ENV PATH=/usr/local/go/bin:${GOPATH}/bin:${PATH}

# --- 2. 安装所有系统依赖和工具 ---
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # PHP 扩展构建依赖
        libpng-dev libjpeg-dev libfreetype6-dev libzip-dev libonig-dev \
        # 常用工具
        supervisor openssh-server sudo curl wget git ca-certificates cron tmux ufw lsof \
        net-tools vim nano less grep findutils tar gzip bzip2 unzip procps iputils-ping \
        dnsutils sshpass inotify-tools \
        # Python
        python3 python3-pip \
        # Java (运行CloudSaver)
        openjdk-11-jre-headless \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    # 创建python软链接
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && ln -sf /usr/bin/pip3 /usr/bin/pip

# --- 3. 安装特定语言环境和工具 ---
# 安装 Node.js 18
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get update && apt-get install -y nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 安装 Go
RUN wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -O go.tar.gz && \
    tar -C /usr/local -xzf go.tar.gz && \
    rm go.tar.gz

# 安装 kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# --- 4. 安装 PHP 扩展 ---
RUN docker-php-ext-install mysqli pdo_mysql gd mbstring zip

# --- 5. 安装 Python 依赖 ---
RUN pip install --no-cache-dir \
    requests PyYAML apscheduler beautifulsoup4 lxml \
    Flask Flask-APScheduler Flask-Login anytree colorlog treelib

# --- 6. 复制和配置应用程序 ---
# 从 cloudsaver_ref 阶段复制 CloudSaver 应用文件
COPY --from=cloudsaver_ref /app /opt/cloudsaver

# 复制自定义配置文件
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY docker-entrypoint.sh /

# --- 7. 设置目录和权限 ---
# 为CloudSaver创建目录并授权
RUN mkdir -p /opt/cloudsaver/data /opt/cloudsaver/config && \
    chown -R www-data:www-data /opt/cloudsaver && \
    chmod -R 775 /opt/cloudsaver

# 配置Apache和Web目录
RUN mkdir -p /var/www/html/maccms/runtime && \
    chown -R www-data:www-data /var/www/html && \
    chmod -R 775 /var/www/html && \
    chmod -R 777 /var/www/html/maccms/runtime && \
    # 修改Apache的DocumentRoot
    sed -i 's|/var/www/html|/var/www/html/maccms|g' /etc/apache2/sites-available/000-default.conf && \
    # 在apache2.conf中也建议修改，确保一致性
    sed -i 's|/var/www/html|/var/www/html/maccms|g' /etc/apache2/apache2.conf

# 配置SSH
RUN mkdir /var/run/sshd

# 赋予入口脚本执行权限
RUN chmod +x /docker-entrypoint.sh

# --- 8. 暴露端口和定义启动命令 ---
EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
# CMD 会作为参数传递给 ENTRYPOINT
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
