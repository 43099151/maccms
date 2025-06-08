#---------------------------------------------------------------------
# 阶段 1: cloudsaver_ref (无变化)
#---------------------------------------------------------------------
    FROM jiangrui1994/cloudsaver:latest AS cloudsaver_ref

    #---------------------------------------------------------------------
    # 阶段 2: 最终镜像 (基于 Alpine, 使用 Nginx + PHP-FPM)
    #---------------------------------------------------------------------
    # 使用官方的 FPM Alpine 镜像
    FROM php:7.4.33-fpm-alpine
    
    # --- 1. 设置环境变量 ---
    ENV TZ=Asia/Shanghai \
        GOPATH=/go \
        GO_VERSION=1.24.4
    ENV PATH=/usr/local/go/bin:${GOPATH}/bin:${PATH}
    
    # --- 2. 安装所有系统依赖和工具 (使用 apk) ---
    RUN apk update && \
        # 启用 community 仓库
        echo "http://dl-cdn.alpinelinux.org/alpine/v$(cut -d'.' -f1,2 /etc/alpine-release)/community" >> /etc/apk/repositories && \
        #
        # --- 分组安装 ---
        #
        # 组1：核心服务
        apk add --no-cache nginx supervisor && \
        #
        # 组2：PHP扩展的编译依赖
        apk add --no-cache libpng-dev jpeg-dev freetype-dev libzip-dev oniguruma-dev && \
        #
        # 组3：语言和运行时环境
        apk add --no-cache python3 py3-pip nodejs npm openjdk11-jre go && \
        #
        # 组4：常用工具 (已使用正确的 Alpine 包名)
        apk add --no-cache \
            openssh sudo curl wget git ca-certificates dcron tmux \
            lsof vim nano less grep findutils tar gzip bzip2 \
            unzip procps iproute2 iputils bind-tools sshpass inotify-tools
    
    # --- 3. 安装 PHP 扩展 ---
    # 注意：fpm版本没有预装mysqli, pdo_mysql，所以我们需要安装它们
    RUN docker-php-ext-install mysqli pdo_mysql gd mbstring zip
    
    # --- 4. 安装 Python 依赖 ---
    RUN pip install --no-cache-dir requests PyYAML apscheduler beautifulsoup4 lxml Flask Flask-APScheduler Flask-Login anytree colorlog treelib
    
    # --- 5. 复制和配置应用程序 ---
    # 5a. 从 cloudsaver_ref 复制 CloudSaver
    COPY --from=cloudsaver_ref /app /opt/cloudsaver
    
    # 5b. 复制我们自己的配置文件
    # 我们需要为 Nginx 和 Supervisor 提供配置文件
    COPY nginx.conf /etc/nginx/http.d/default.conf
    COPY supervisord.conf /etc/supervisord.conf
    COPY docker-entrypoint.sh /
    RUN sed -i 's/\r$//' /docker-entrypoint.sh
    # --- 6. 设置目录和权限 ---
    # FPM镜像默认使用 www-data 用户，这很方便
    RUN mkdir -p /opt/cloudsaver/data /opt/cloudsaver/config && \
        chown -R www-data:www-data /opt/cloudsaver && \
        chmod -R 775 /opt/cloudsaver
    
    RUN mkdir -p /var/www/html/maccms/runtime && \
        chown -R www-data:www-data /var/www/html && \
        chmod -R 775 /var/www/html && \
        chmod -R 777 /var/www/html/maccms/runtime
    
    RUN mkdir -p /var/log/supervisor && \
        mkdir -p /var/run/sshd && \
        chmod +x /docker-entrypoint.sh
    
    # --- 7. 暴露端口和定义启动命令 ---
    EXPOSE 80
    ENTRYPOINT ["/docker-entrypoint.sh"]
    CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
