# 使用官方 Docker CLI 镜像 (基于 Alpine)
FROM docker:cli

# 设置工作目录
WORKDIR /app

# 安装必要的工具 (grep 用于文本匹配)
RUN apk add --no-cache grep

# 复制核心脚本
COPY src/entrypoint.sh /app/entrypoint.sh

# 创建数据挂载点
RUN mkdir -p /data

# 赋予脚本执行权限
RUN chmod +x /app/entrypoint.sh

# 容器启动入口
ENTRYPOINT ["/app/entrypoint.sh"]
