#!/bin/sh
set -e

# 定义源 cron 文件和目标 cron 文件路径
CRON_SOURCE_FILE="/var/www/html/cron/maccms_cron"
CRON_TARGET_FILE="/etc/cron.d/maccms_cron"

# 函数：加载/更新 cron 任务
update_cron_tasks() {
    if [ -f "$CRON_SOURCE_FILE" ]; then
        cp "$CRON_SOURCE_FILE" "$CRON_TARGET_FILE"
        chmod 0644 "$CRON_TARGET_FILE"
        echo "[INFO] Cron tasks updated from $CRON_SOURCE_FILE"
    else
        echo "[WARN] Cron source file $CRON_SOURCE_FILE not found. No cron tasks loaded."
        # 如果源文件不存在，删除目标文件，以避免执行旧的或无效的 cron 任务
        if [ -f "$CRON_TARGET_FILE" ]; then
            rm "$CRON_TARGET_FILE"
            echo "[INFO] Removed $CRON_TARGET_FILE as source file is missing."
        fi
    fi
}

# 确保源文件所在的目录存在
mkdir -p "$(dirname "$CRON_SOURCE_FILE")"

# 初始加载 cron 任务
echo "[INFO] 初始化 cron 任务..."
update_cron_tasks

# 后台监控 cron 源文件的变化
(
    echo "[INFO] 开始监控 cron 配置文件变化..."
    while true; do
        # 等待文件创建、修改、删除、移动事件
        # 使用 --monitor 选项来持续监控，而不是单次事件后退出
        # 监控目录以捕获文件创建/删除，监控文件以捕获修改
        inotifywait --monitor --event create,modify,delete,move --format '%e %w%f' "$(dirname "$CRON_SOURCE_FILE")" | \
        while read -r events file_path; do
            if [ "$file_path" = "$CRON_SOURCE_FILE" ]; then
                echo "[INFO] Detected change ($events) in $CRON_SOURCE_FILE. Reloading cron tasks."
                update_cron_tasks
            fi
        done
    done
) &

# 确保supervisor配置目录存在并具有正确的权限
SUPERVISOR_CONF_DIR="/var/www/html/supervisor/conf.d"
mkdir -p "$SUPERVISOR_CONF_DIR"
chmod -R 755 "$SUPERVISOR_CONF_DIR"
echo "[INFO] 确保supervisor配置目录 $SUPERVISOR_CONF_DIR 存在并具有正确的权限。"

# 配置SSH访问
if [ -n "$SSH_PASSWORD" ]; then
    echo "root:$SSH_PASSWORD" | chpasswd
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    echo "[INFO] Root SSH 密码已通过 SSH_PASSWORD 环境变量设置。"
else
    echo "[WARN] 未设置 SSH_PASSWORD 环境变量，root 密码未变更。"
fi

echo "[INFO] 容器初始化完成，启动服务..."

# 执行传递给脚本的原始命令 (例如 supervisord)
exec "$@"
