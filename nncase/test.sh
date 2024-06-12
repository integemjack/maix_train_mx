#!/bin/bash

# 启用 Docker CLI 实验功能
mkdir -p ~/.docker/cli-plugins
curl -SL https://github.com/docker/buildx/releases/download/v0.9.1/buildx-v0.9.1.linux-amd64 -o ~/.docker/cli-plugins/docker-buildx
chmod +x ~/.docker/cli-plugins/docker-buildx

cat <<EOF > ~/.docker/config.json
{
  "experimental": "enabled"
}
EOF

# 安装 binfmt 支持以便处理多平台
docker run --privileged --rm tonistiigi/binfmt --install all

# 创建并使用 Buildx 构建器
docker buildx create --name mybuilder --use

# 初始化构建器
docker buildx inspect mybuilder --bootstrap

# 使用 Buildx 构建并推送多平台镜像
docker buildx build --platform linux/amd64,linux/arm64 -t your-repo/your-image:latest --push .

echo "Docker镜像构建并推送完成。"