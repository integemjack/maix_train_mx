#!/bin/bash

# 检查 buildx 是否已安装
if ! docker buildx version &>/dev/null; then
  # 启用 Docker CLI 实验功能
  mkdir -p ~/.docker/cli-plugins
  curl -SL https://github.com/docker/buildx/releases/download/v0.9.1/buildx-v0.9.1.linux-amd64 -o ~/.docker/cli-plugins/docker-buildx
  chmod +x ~/.docker/cli-plugins/docker-buildx

  cat <<EOF > ~/.docker/config.json
{
  "experimental": "enabled"
}
EOF

  echo "buildx 已成功安装并配置"
else
  echo "buildx 已存在，跳过安装步骤"
fi

# 安装 binfmt 支持以便处理多平台
docker run --privileged --rm tonistiigi/binfmt --install all

# 创建并使用 Buildx 构建器
docker buildx create --name mybuilder --use

# 初始化构建器
docker buildx inspect mybuilder --bootstrap

# 使用 Buildx 构建并推送多平台镜像
docker buildx build --platform linux/arm64,linux/amd64 -t integem/notebook:maix_train_mx_v3 --push .

echo "Docker镜像构建并推送完成。"

docker run --rm -it -p 8888:8888 integem/notebook:maix_train_mx_v3 bash -c "cd maix_train_mx && python train.py -t detector -di ../signal/images -dx ../signal/xml -ep 200 -ap 0.75 -bz 8 train && exit"

echo "Docker测试完成。"