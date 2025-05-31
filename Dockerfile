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

# 安装 PHP 扩展
RUN docker-php-ext-install mysqli pdo_mysql gd mbstring zip

# 安装quark-auto-save依赖
RUN pip install --no-cache-dir \
    requests PyYAML apscheduler beautifulsoup4 lxml \
    Flask Flask-APScheduler Flask-Login anytree colorlog treelib

# 复制配置文件
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY docker-entrypoint.sh /

# 设置权限
RUN chmod +x /docker-entrypoint.sh && \
    mkdir -p /var/www/html/runtime && \
    chown -R www-data:www-data /var/www/html && \
    chmod -R 775 /var/www/html && \
    chmod -R 777 /var/www/html/runtime && \
    mkdir -p /var/run/sshd

# 暴露端口
EXPOSE 80 22

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
