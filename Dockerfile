# 使用 php:7.4.33apache 基础镜像
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
        # 如果您的应用仍需连接MySQL/MariaDB，mysqli 和 pdo_mysql 扩展是必要的
    && docker-php-ext-install mysqli pdo_mysql gd mbstring zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

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
    # 安全警告：已移除硬编码的root密码 (echo 'root:884gerenwu' | chpasswd)。
    # 直接在 Dockerfile 中写入密码会将其暴露，非常不安全。
    # 推荐的替代方案：
    # 1. SSH密钥认证 (最安全)：
    #    a. 在构建上下文创建 .ssh 目录，放入您的公钥 id_rsa.pub。
    #    b. 在 Dockerfile 中添加 (在安装 openssh-server 之后)：
    #       RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh
    #       COPY .ssh/id_rsa.pub /root/.ssh/authorized_keys
    #       RUN chmod 600 /root/.ssh/authorized_keys && chown root:root /root/.ssh/authorized_keys && \
    #           sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config # 禁用密码登录
    # 2. 构建参数 (ARG) (相对安全，用于开发或特定场景)：
    #    a. 在 Dockerfile 顶部添加: ARG ROOT_PASSWORD
    #    b. 在此处的 RUN 指令中，替换密码设置命令为: \
    #       ( [ -z "${ROOT_PASSWORD}" ] && echo "警告: 未设置ROOT_PASSWORD，root可能无密码或使用默认密码。" || echo "root:${ROOT_PASSWORD}" | chpasswd ) && \
    #    c. 构建镜像时传入参数: docker build --build-arg ROOT_PASSWORD=your_secure_password -t myimage .
    # 确保root用户可以通过SSH登录 (如果需要):
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# 暴露端口
EXPOSE 80 22

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]

# 说明：如需挂载本地www目录，请在docker run时添加
# -v /你的本地路径/www:/var/www/html
