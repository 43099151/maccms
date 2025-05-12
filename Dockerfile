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
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
   
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
    echo 'root:884gerenwu' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# 暴露端口
EXPOSE 80 22

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]

# 添加定时任务到 /etc/cron.d/maccms_cron
COPY maccms_cron /etc/cron.d/maccms_cron
RUN chmod 0644 /etc/cron.d/maccms_cron && \
    crontab /etc/cron.d/maccms_cron
