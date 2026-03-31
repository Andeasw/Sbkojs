# 必须使用基于 Debian 的 slim 镜像 (不能用 alpine)
# 因为脚本下载的二进制核心文件（sb, 2go等）是基于 glibc 编译的，在 alpine (musl) 环境下会报 "not found" 错误。
FROM node:20-slim

# 安装系统级依赖
# tini: 解决 Docker 下 Node 作为 PID 1 无法回收僵尸进程的问题（脚本使用了大量 nohup 和后台进程）
# openssl: 脚本中生成自签证书必须用到
# curl: 脚本中用于获取 IP 和检测 YouTube 连通性
# procps: 包含 pkill 命令，脚本中用于重启进程
# ca-certificates: 确保 HTTPS 下载二进制文件时证书校验通过
RUN apt-get update && apt-get install -y --no-install-recommends \
    tini \
    openssl \
    curl \
    procps \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 初始化 npm 项目并安装脚本依赖模块
# (如果本地有 package.json，这里可以替换为 COPY package*.json ./ && npm install)
RUN npm init -y && \
    npm install express axios dotenv

# 拷贝代码到容器内
COPY index.js /app/index.js

# 创建缓存目录并赋予读写执行权限
RUN mkdir -p /app/.cache && \
    chmod 777 /app/.cache

# 暴露主 Web 端口 (默认 3000)
EXPOSE 3000

# 使用 tini 作为入口点，接管进程管理
ENTRYPOINT ["/usr/bin/tini", "--"]

# 启动脚本
CMD ["node", "index.js"]
