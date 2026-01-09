#!/bin/bash

# 定义镜像名称
IMAGE_NAME="irol765/docker-guard:latest"
CONTAINER_NAME="docker-guard"
DATA_DIR="/root/docker-guard"

echo "================================================"
echo "   🛡️ Docker Guard 一键安装脚本 (Auto-Detect)"
echo "================================================"

# 1. 检测 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ 错误: 未找到 docker 命令。请先安装 Docker。"
    exit 1
fi

# 2. 自动探测宿主机 API 版本
echo "🔍 正在探测 Docker API 版本..."
HOST_API_VERSION=$(docker version --format '{{.Server.APIVersion}}')

if [ -z "$HOST_API_VERSION" ]; then
    echo "⚠️ 警告: 无法获取 API 版本，将使用默认模式启动。"
    ENV_ARG=""
else
    echo "✅ 检测到宿主机 API 版本: $HOST_API_VERSION"
    ENV_ARG="-e DOCKER_API_VERSION=$HOST_API_VERSION"
fi

# 3. 准备环境
echo "📂 准备数据目录: $DATA_DIR"
mkdir -p "$DATA_DIR"

# 4. 清理旧容器
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "🧹 删除旧容器..."
    docker rm -f "$CONTAINER_NAME"
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
    echo "📝 白名单路径: $DATA_DIR/whitelist.txt"
    echo "👀 查看日志: docker logs -f $CONTAINER_NAME"
    echo "================================================"
else
    echo "❌ 启动失败，请检查日志："
    docker logs "$CONTAINER_NAME"
fi
