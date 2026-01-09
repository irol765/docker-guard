# 定义镜像名称
IMAGE_NAME="irol765/docker-guard:latest"
CONTAINER_NAME="docker-guard"
DATA_DIR="/root/docker-guard"
WHITELIST_FILE="$DATA_DIR/whitelist.txt"

echo "================================================"
echo "   🛡️ Docker Guard 一键安装脚本 (交互版)"
echo "================================================"

# 1. 检测 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ 错误: 未找到 docker 命令。请先安装 Docker。"
    exit 1
fi

# 2. 自动探测或手动指定 API 版本
if [ -n "$1" ]; then
    echo "🔧 [手动模式] 使用用户指定的 API 版本: $1"
    HOST_API_VERSION="$1"
    ENV_ARG="-e DOCKER_API_VERSION=$HOST_API_VERSION"
else
    echo "🔍 [自动模式] 正在探测宿主机 Docker API 版本..."
    HOST_API_VERSION=$(docker version --format '{{.Server.APIVersion}}')

    if [ -z "$HOST_API_VERSION" ]; then
        echo "⚠️ 警告: 无法获取 API 版本，将使用默认模式启动。"
        ENV_ARG=""
    else
        echo "✅ 检测到宿主机 API 版本: $HOST_API_VERSION"
        ENV_ARG="-e DOCKER_API_VERSION=$HOST_API_VERSION"
    fi
fi

# 3. 准备环境 & 白名单交互逻辑 (新增优化)
echo "📂 准备数据目录: $DATA_DIR"
mkdir -p "$DATA_DIR"

if [ -f "$WHITELIST_FILE" ] && [ -s "$WHITELIST_FILE" ]; then
    echo ""
    echo "📋 发现现有白名单配置："
    echo "--------------------------------------------------"
    cat "$WHITELIST_FILE"
    echo "--------------------------------------------------"
    echo "💡 提示：保留白名单将沿用上述配置；删除白名单将触发'自动学习'重新扫描。"
    read -p "❓ 是否保留现有白名单？ [Y/n] (默认: Y): " choice
    case "$choice" in 
        n|N ) 
            echo "🗑️  已删除旧白名单。Docker Guard 将在启动时重新扫描当前环境。"
            rm "$WHITELIST_FILE"
            ;;
        * ) 
            echo "✅ 已保留现有白名单。"
            ;;
    esac
    echo ""
fi

# 4. 清理旧容器
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "🧹 删除旧容器..."
    docker rm -f "$CONTAINER_NAME" > /dev/null
fi

# 5. 启动容器
echo "🚀 正在启动 Docker Guard..."
docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  $ENV_ARG \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$DATA_DIR":/data \
  "$IMAGE_NAME"

# 6. 验证状态
sleep 2
if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
    echo "================================================"
    echo "🎉 安装成功！Docker Guard 正在运行。"
    echo "📝 白名单路径: $WHITELIST_FILE"
    echo "👀 查看日志: docker logs -f $CONTAINER_NAME"
    echo "================================================"
else
    echo "❌ 启动失败，请检查日志："
    docker logs "$CONTAINER_NAME"
fi
