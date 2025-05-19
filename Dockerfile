# 使用 php:7.4.33-apache 基础镜像
FROM php:7.4.33-apache

# 设置环境变量
ENV TZ=Asia/Shanghai

# 安装必要扩展和工具
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
    && docker-php-ext-install mysqli pdo_mysql gd mbstring zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/* 

# 安装 Node.js 18
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# 安装 Python3 和 pip
RUN apt-get update \
    && apt-get install -y --no-install-recommends apt-transport-https ca-certificates \
    && apt-get install -y --no-install-recommends python3 python3-pip \
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && ln -sf /usr/bin/pip3 /usr/bin/pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 安装quark-auto-save依赖
RUN pip install --no-cache-dir \
    requests PyYAML apscheduler beautifulsoup4 lxml \
    Flask Flask-APScheduler Flask-Login anytree colorlog treelib

# 安装kubectl
RUN curl -LO https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

# 复制supervisor配置和入口脚本
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY docker-entrypoint.sh /

# 复制应用代码（如需挂载本地目录，可在docker run时用-v参数覆盖此目录）
COPY www /var/www/html

# 设置权限
RUN chmod +x /docker-entrypoint.sh && \
    chown -R www-data:www-data /var/www/html && \
    chmod -R 775 /var/www/html && \
    mkdir -p /var/www/html/runtime && \
    chown -R www-data:www-data /var/www/html/runtime && \
    chmod -R 777 /var/www/html/runtime && \
    mkdir -p /var/run/sshd && \
    echo "root:${DOCKER_ROOT_PASSWORD:-Changeme123!}" | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# 暴露端口
EXPOSE 80 22

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
