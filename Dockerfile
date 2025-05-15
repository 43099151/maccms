FROM php:7.4.33-apache

# 设置环境变量，防止交互
ENV DEBIAN_FRONTEND=noninteractive

# 安装常用依赖
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libzip-dev \
        libpng-dev \
        libjpeg-dev \
        libfreetype6-dev \
        libonig-dev \
        libxml2-dev \
        zip \
        unzip \
        git \
        curl \
        wget \
        supervisor \
        cron \
        openssh-server \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_mysql gd mbstring zip xml

# 安装 Node.js 18
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g pnpm

# 安装 Python3 和 pip
RUN apt-get update \
    && apt-get install -y --no-install-recommends apt-transport-https ca-certificates \
    && apt-get install -y --no-install-recommends python3 python3-pip \
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && ln -sf /usr/bin/pip3 /usr/bin/pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 安装quark-auto-save依赖
RUN cd /tmp \
    && git clone https://github.com/quarkcms/quark-auto-save.git \
    && cd quark-auto-save \
    && pnpm install \
    && pnpm build \
    && mkdir -p /var/www/html/quark-auto-save \
    && cp -r dist/* /var/www/html/quark-auto-save/ \
    && cd / && rm -rf /tmp/quark-auto-save

# 复制supervisor配置和入口脚本
COPY supervisord.conf /etc/supervisord.conf
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# 复制www目录到挂载目录
COPY www /var/www/html/

# 设置权限
RUN chown -R www-data:www-data /var/www/html

# 暴露端口
EXPOSE 80 22

# 设置入口
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
