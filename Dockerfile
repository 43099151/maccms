#---------------------------------------------------------------------
# 阶段 1: cloudsaver_ref (无变化)
#---------------------------------------------------------------------
FROM jiangrui1994/cloudsaver:latest AS cloudsaver_ref

#---------------------------------------------------------------------
# 阶段 2: 最终镜像
#---------------------------------------------------------------------
FROM php:7.4.33-fpm-alpine

# --- 1. 设置环境变量 ---
ENV TZ=Asia/Shanghai \
    GOPATH=/go \
    GO_VERSION=1.24.4
ENV PATH=/usr/local/go/bin:${GOPATH}/bin:${PATH}

# --- 2. 安装所有系统依赖和工具 ---
# 将 apk add 合并为一层可以减小镜像体积
RUN apk update && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v$(cut -d'.' -f1,2 /etc/alpine-release)/community" >> /etc/apk/repositories && \
    apk add --no-cache \
        # 核心服务
        nginx supervisor \
        # PHP扩展依赖
        libpng-dev jpeg-dev freetype-dev libzip-dev oniguruma-dev \
        # 语言和运行时
        python3 py3-pip nodejs npm openjdk11-jre go \
        # 常用工具
        openssh sudo curl wget git ca-certificates dcron tmux \
        lsof vim nano less grep findutils tar gzip bzip2 \
        unzip procps iproute2 iputils bind-tools sshpass inotify-tools

# --- 3. 安装 PHP 扩展 ---
RUN docker-php-ext-install mysqli pdo_mysql gd mbstring zip

# --- 4. 安装 Python 依赖 ---
RUN pip install --no-cache-dir requests PyYAML apscheduler beautifulsoup4 lxml Flask Flask-APScheduler Flask-Login anytree colorlog treelib

# --- 5. 复制和配置应用程序 ---
COPY --from=cloudsaver_ref /app /opt/cloudsaver

# 复制配置文件
COPY nginx.conf /etc/nginx/http.d/default.conf
# !!! 修正 Supervisor 主配置文件的路径 !!!
COPY supervisord.conf /etc/supervisord.conf
COPY docker-entrypoint.sh /

# !!! 使用更强的修复命令，同时处理BOM和CRLF !!!
RUN sed -i '1s/^\xef\xbb\xbf//; s/\r$//' /docker-entrypoint.sh

# --- 6. 设置目录和权限 ---
# 将权限设置合并，并且确保脚本有执行权限
RUN mkdir -p /opt/cloudsaver/data /opt/cloudsaver/config && \
    chown -R www-data:www-data /opt/cloudsaver && \
    chmod -R 775 /opt/cloudsaver && \
    mkdir -p /var/www/html/maccms/runtime && \
    # 创建 supervisor 子配置目录，以防将来使用
    mkdir -p /etc/supervisor/conf.d && \
    chown -R www-data:www-data /var/www/html && \
    chmod -R 775 /var/www/html && \
    chmod -R 777 /var/www/html/maccms/runtime && \
    mkdir -p /var/run/sshd && \
    # !!! 确保脚本有执行权限 !!!
    chmod +x /docker-entrypoint.sh

# --- 7. 暴露端口和定义启动命令 ---
EXPOSE 80
ENTRYPOINT ["/docker-entrypoint.sh"]
# !!! 确保 CMD 调用的是正确路径下的主配置文件 !!!
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
