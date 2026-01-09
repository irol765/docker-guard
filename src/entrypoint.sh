#!/bin/sh

WHITELIST_FILE="/data/whitelist.txt"

# ---------------------------------------------------------
# [阶段一] 初始化白名单 (自动学习模式)
# ---------------------------------------------------------

# 如果文件不存在，或文件为空，则触发自动学习
if [ ! -f "$WHITELIST_FILE" ] || [ ! -s "$WHITELIST_FILE" ]; then
    echo "🚀 [初始化] 未检测到有效白名单。"
    echo "🧠 [智能学习] 正在扫描当前宿主机环境..."
    
    # 扫描所有现有镜像，去重，写入白名单
    # 使用 {{.Repository}} 确保只获取镜像名，不含 Tag
    docker images --format "{{.Repository}}" | grep -v "<none>" | sort | uniq > "$WHITELIST_FILE"
    
    # 强制将自己加入白名单 (防止误杀自己)
    # 注意：这里假设用户拉取的是 irol765/docker-guard，如果改名需手动调整
    echo "irol765/docker-guard" >> "$WHITELIST_FILE"
    echo "docker:cli" >> "$WHITELIST_FILE"
    
    echo "✅ 白名单生成完毕！内容如下："
    cat "$WHITELIST_FILE"
    echo "---------------------------------------------------------"
else
    echo "📂 [加载] 检测到现有白名单，跳过学习模式。"
fi

# ---------------------------------------------------------
# [阶段二] 开始无限循环巡逻
# ---------------------------------------------------------

echo "🛡️  Docker Guard 启动巡逻！(周期: 10秒)"

while true; do
    # 使用 'docker ps -a' 获取所有容器 (包括运行中和已停止的)
    # 格式: ID 镜像名
    docker ps -a --format "{{.ID}} {{.Image}}" | while read container_id image_name; do
        
        # 1. 提取纯镜像名 (移除 Tag 版本号)
        # 例如: mysql:5.7 -> mysql
        # 如果你想精确匹配版本，可以去掉这一步处理
        clean_image_name=$(echo "$image_name" | cut -d: -f1)
        
        # 2. 检查是否在白名单中
        # 使用 grep 全字匹配
        if grep -q "^${clean_image_name}$" "$WHITELIST_FILE"; then
            # 在白名单内，安全，跳过
            :
        else
            echo "🚨 [发现非法入侵] 容器: $image_name (ID: $container_id)"
            
            # 3. 处决容器 (强制删除)
            echo "🔪 正在强制删除容器..."
            docker rm -f "$container_id"
            
            # 4. 清理镜像 (防止再次启动)
            echo "🧹 正在清理恶意镜像..."
            docker rmi -f "$image_name"
            
            echo "✅ 威胁已清除。"
        fi
    done
    
    # 休息 10 秒
    sleep 10
done
