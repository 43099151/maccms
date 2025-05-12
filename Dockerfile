# 使用 php:7.4.33-apache 基础镜像
FROM php:7.4.33-apache

# 设置环境变量
ENV TZ=Asia/Shanghai

# 安装必要扩展和工具
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
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
    && docker-php-ext-install mysqli pdo_mysql gd mbstring zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/* 

# 复制supervisor配置和入口脚本
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY docker-entrypoint.sh /

# 复制应用代码（如需挂载本地目录，可在docker run时用-v参数覆盖此目录）
COPY www /var/www/html

# 复制所有cron任务文件到/etc/cron.d，并设置权限
RUN if [ -d /var/www/html/cron ]; then \
      cp /var/www/html/cron/* /etc/cron.d/ && \
      chmod 0644 /etc/cron.d/* ; \
    fi

# 设置权限
RUN chmod +x /docker-entrypoint.sh && \
    chown -R www-data:www-data /var/www/html && \
    chmod -R 775 /var/www/html && \
    mkdir -p /var/www/html/runtime && \
    chown -R www-data:www-data /var/www/html/runtime && \
    chmod -R 777 /var/www/html/runtime && \
    mkdir -p /var/run/sshd && \
    echo 'root:884gerenwu' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# 下载 CloudSaver 源码到指定目录
RUN cd /var/www/html && \
    git clone https://github.com/jiangrui1994/CloudSaver.git cloudsaver

# 安装 Node.js 18 和 pnpm
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g pnpm

# 安装前端依赖并构建
RUN cd /var/www/html/cloudsaver && \
    pnpm install && \
    pnpm build:frontend

# 安装后端依赖并构建
RUN cd /var/www/html/cloudsaver/backend && \
    pnpm install && \
    pnpm build

# 创建数据和配置目录
RUN mkdir -p /var/www/html/cloudsaver/data /var/www/html/cloudsaver/config

# 暴露端口
EXPOSE 80 22

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
