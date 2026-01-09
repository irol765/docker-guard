# **🛡️ Docker Guard (容器安全看门狗)**

**Docker Guard** 是一个极简、高效的 Docker 安全守护容器。它像一个 24 小时巡逻的保安，自动监控并清除任何未授权的恶意容器（如挖矿病毒、非法镜像）。

## **✨ 核心功能**

* **🧠 智能初始化**：首次启动时，**自动学习**当前宿主机上所有已存在的镜像并加入白名单，防止误杀业务容器。  
* **🚓 实时巡逻**：每 **10 秒** 扫描一次全系统（包括运行中和已停止的容器）。  
* **⚔️ 斩草除根**：一旦发现不在白名单的容器：  
  1. 立即**强制停止并删除容器**。  
  2. 顺手**删除对应的恶意镜像**，不留垃圾。  
* **📦 开箱即用**：无需手动创建配置文件或目录，Docker 会自动处理。

## **🚀 一键部署 (Quick Start)**

🚀 极速部署 (推荐)

我们提供了一个万能安装脚本，自动处理目录创建、旧容器清理和 API 版本检测。

```bash
# 下载并运行安装脚本
curl -sSL https://raw.githubusercontent.com/irol765/docker-guard/main/scripts/install.sh | bash
```


如需手动部署直接复制以下命令在服务器上运行即可。  
(注意：Docker 会自动创建 /root/docker-guard 目录用于存放白名单，无需手动新建)  

先查看API版本
```bash
# 查看 API 版本命令
docker version -f '{{.Server.APIVersion}}'
```
替换API版本

```bash
docker run -d \
  --name docker-guard \
  --restart unless-stopped \
  -e DOCKER_API_VERSION=替换API版本 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /root/docker-guard:/data \
  irol765/docker-guard:latest
```

⚠️ 警告：请勿手动创建白名单文件！
请让容器首次运行自动生成 whitelist.txt。如果在容器启动前手动创建了该文件，会导致**“自动学习”功能失效**，从而误杀其他正常容器。

如果无法正常使用请先运行以下代码，清除whitelist.txt和老容器，再启动容器。

```bash
docker rm -f docker-guard
rm /root/docker-guard/whitelist.txt
```

## **⚙️ 白名单管理 (Whitelist)**

容器启动后，白名单文件会自动生成在宿主机的 **/root/docker-guard/whitelist.txt**。

### **1\. 查看当前的白名单**

```bash
cat /root/docker-guard/whitelist.txt
```

### **2\. 添加新的合法镜像**

如果你以后需要部署新的服务（例如 redis），请务必先将镜像名添加到白名单中，否则会被看门狗杀掉。

**操作步骤：**

1. 编辑白名单文件：
```bash
vi /root/docker-guard/whitelist.txt  
```
2. 在末尾添加一行：如redis  
3. 保存退出 (:wq)。  
4. **即时生效**，无需重启看门狗。

## **📝 查看执法日志**

想看看最近拦截了哪些入侵行为？查看容器日志即可：

```bash
docker logs \--tail 50 \-f docker-guard
```

**日志示例：**

🛡️ Docker 看门狗启动！开始巡逻...  
🚨 \[发现非法入侵\] 未知容器: hello-world (ID: 01a1b13d3c39)  
🔪 正在处决容器...  
🧹 正在清理非法镜像...  
✅ 威胁已清除

## **⚠️ 注意事项**

* **挂载路径**：建议将数据卷挂载到 /root/docker-guard 或其他持久化目录，确保白名单文件不会丢失。  
* **首次运行**：请确保在服务器干净（没有病毒）的状态下首次运行，因为它会默认信任当前所有的镜像。

*Maintained by irol765*
