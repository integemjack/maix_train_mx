#!/bin/bash

set -e

# 安装 QEMU
echo "安装 QEMU..."
sudo apt-get update
sudo apt-get install -y qemu-user-static

# 安装 Docker Buildx
echo "安装 Docker Buildx..."
docker run --privileged --rm tonistiigi/binfmt --install all
docker buildx create --use
docker buildx inspect --bootstrap

# 构建多架构镜像
echo "构建多架构镜像..."
docker buildx build --platform linux/amd64,linux/arm64 -t integem/notebook:maix_train_mx_v3 --load .

# 运行 arm64 版本并测试 Python 运行
echo "运行和测试 arm64 版本的 Docker 镜像..."
docker run --rm --platform linux/arm64 -it -p 8888:8888 integem/notebook:maix_train_mx_v3 bash -c "cd /app/maix_train_mx && python train.py -t detector -di ../signal/images -dx ../signal/xml -ep 200 -ap 0.75 -bz 8 train"

# 检查测试结果
if [ $? -eq 0 ]; then
    echo "测试通过，推送镜像到 Docker Hub..."
    docker buildx build --platform linux/amd64,linux/arm64 -t integem/notebook:maix_train_mx_v3 --push .
else
    echo "测试失败，退出..."
    exit 1
fi

# 删除环境
echo "清理环境..."
# 删除 QEMU
sudo apt-get remove -y qemu-user-static
sudo apt-get autoremove -y
sudo apt-get clean

# 删除 Docker Buildx builder
docker buildx rm

# 删除本地镜像
docker rmi integem/notebook:maix_train_mx_v3

echo "所有步骤完成并清理环境！"