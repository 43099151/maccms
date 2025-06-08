# 第一阶段：构建环境
FROM php:7.4.33-apache AS builder

ENV TZ=Asia/Shanghai

# 安装构建依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl wget git ca-certificates \
        libpng-dev libjpeg-dev libfreetype6-dev libzip-dev libonig-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 安装 PHP 扩展
RUN docker-php-ext-install mysqli pdo_mysql gd mbstring zip

# 安装 kubectl

# 第三阶段：提取 CloudSaver
FROM jiangrui1994/cloudsaver:latest AS cloudsaver_builder
COPY /app /app
RUN curl -LO https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

# 第二阶段：最终镜像
FROM php:7.4.33-apache

ENV TZ=Asia/Shanghai

# 安装运行时必要的包
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        libpng-dev \
        libjpeg-dev \
        libfreetype6-dev \
        libzip-dev \
        libonig-dev \
        supervisor \
        openssh-server \
        sudo \
        curl \
        wget \
        cron \
        tmux \
        ufw \
        lsof \
        net-tools \
        vim \
        nano \
        less \
        grep \
        findutils \
        tar \
        gzip \
        bzip2 \
        unzip \
        procps \
        iputils-ping \
        dnsutils \
        sshpass \
        inotify-tools \
        python3 \
        python3-pip \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && ln -sf /usr/bin/pip3 /usr/bin/pip

# 安装 Node.js 18
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 安装 Go 语言环境
RUN wget https://go.dev/dl/go1.24.4.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.24.4.linux-amd64.tar.gz && \
    rm go1.24.4.linux-amd64.tar.gz && \
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile && \
    echo 'export GOPATH=/var/www/html/go' >> /etc/profile && \
    echo 'export PATH=$PATH:$GOPATH/bin' >> /etc/profile

# 从 cloudsaver_builder 阶段复制 CloudSaver 应用文件
COPY --from=cloudsaver_builder /app /opt/cloudsaver

# 安装 PHP 扩展
RUN docker-php-ext-install mysqli pdo_mysql gd mbstring zip

# 设置 CloudSaver 工作目录和权限
RUN mkdir -p /opt/cloudsaver/data && \
    mkdir -p /opt/cloudsaver/config && \
    chown -R www-data:www-data /opt/cloudsaver && \
    chmod -R 775 /opt/cloudsaver

# 安装quark-auto-save依赖
RUN pip install --no-cache-dir \
    requests PyYAML apscheduler beautifulsoup4 lxml \
    Flask Flask-APScheduler Flask-Login anytree colorlog treelib

# 复制配置文件
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY docker-entrypoint.sh /

# 更改 Apache 默认目录
RUN mkdir -p /var/www/html/maccms && \
    chown -R www-data:www-data /var/www/html/maccms && \
    chmod -R 775 /var/www/html/maccms && \
    sed -i 's|/var/www/html|/var/www/html/maccms|g' /etc/apache2/sites-available/000-default.conf && \
    sed -i 's|/var/www/html|/var/www/html/maccms|g' /etc/apache2/apache2.conf

# 设置权限
RUN chmod +x /docker-entrypoint.sh && \
    mkdir -p /var/www/html/maccms/runtime && \
    chown -R www-data:www-data /var/www/html && \
    chmod -R 775 /var/www/html && \
    chmod -R 777 /var/www/html/maccms/runtime && \
    mkdir -p /var/run/sshd

# 暴露端口
EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
