#!/bin/sh

WHITELIST_FILE="/data/whitelist.txt"

# 定义检查与清理函数 (复用逻辑)
check_and_kill() {
    local container_id=$1
    local image_name=$2

    # [优化] 提取纯镜像名 (智能移除 Tag，保留私有仓库端口)
    # 逻辑：只移除行尾的 :tag，而不移除 localhost:5000 中的冒号
    local clean_image_name=$(echo "$image_name" | sed 's/:[^/]*$//')

    # 检查是否在白名单中
    if grep -q "^${clean_image_name}$" "$WHITELIST_FILE"; then
        return
    else
        echo "🚨 [实时拦截] 发现非法入侵: $image_name (ID: $container_id)"
        
        # 1. 毫秒级处决 (先暂停再删除，防止它继续运行代码)
        docker stop "$container_id" > /dev/null 2>&1
        docker rm -f "$container_id" > /dev/null 2>&1
        
        echo "🔪 容器已处决。"
        
        # 2. 清理镜像
        echo "🧹 清理恶意镜像..."
        docker rmi -f "$image_name" > /dev/null 2>&1
        
        echo "✅ 威胁已清除。"
    fi
}

# ---------------------------------------------------------
# [阶段一] 初始化白名单 (自动学习模式)
# ---------------------------------------------------------

if [ ! -f "$WHITELIST_FILE" ] || [ ! -s "$WHITELIST_FILE" ]; then
    echo "🚀 [初始化] 未检测到有效白名单。"
    echo "🧠 [智能学习] 正在扫描当前宿主机环境..."
    
    docker images --format "{{.Repository}}" | grep -v "<none>" | sort | uniq > "$WHITELIST_FILE"
    
    # 将常见的基础镜像和自己加入白名单防止自杀
    echo "docker:cli" >> "$WHITELIST_FILE"
    echo "irol765/docker-guard" >> "$WHITELIST_FILE"
    
    echo "✅ 白名单生成完毕！"
else
    echo "📂 [加载] 使用现有白名单。"
fi

# ---------------------------------------------------------
# [阶段二] 启动全量扫描 (清理之前的漏网之鱼)
# ---------------------------------------------------------
echo "🔍 执行启动前全量清理..."
docker ps -a --format "{{.ID}} {{.Image}}" | while read -r container_id image_name; do
    check_and_kill "$container_id" "$image_name"
done

# ---------------------------------------------------------
# [阶段三] 开启实时事件监听 (Real-time Monitor)
# ---------------------------------------------------------

echo "⚡ Docker Guard 进入实时防御模式 (Event Driven)..."

# 监听 'start' 事件：只要有容器启动，立刻触发
# 使用 {{.Actor.Attributes.image}} 获取标准的镜像名 (API 1.22+)
docker events --filter 'type=container' --filter 'event=start' --format '{{.ID}} {{.Actor.Attributes.image}}' | while read -r container_id image_name; do
    # 只要收到信号，立刻执行检查
    check_and_kill "$container_id" "$image_name"
done
