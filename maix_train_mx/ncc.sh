#!/bin/bash

# 用户自定义变量
CHROOT_DIR="/opt/chroot/x86_64"   # 替换为你想要创建chroot环境的实际路径
CUSTOM_COMMAND=$1                 # 自定义命令作为第一个参数传入

# 检查系统架构
ARCH=$(uname -m)

# 函数：检查并安装缺失的软件包
install_if_missing() {
    if ! dpkg -l | grep -q $1; then
        sudo apt update
        sudo apt install -y $1
    fi
}

# 检查并安装所需的软件包
install_if_missing qemu
install_if_missing qemu-user
install_if_missing qemu-user-static
install_if_missing binfmt-support
install_if_missing debootstrap

if [ "$ARCH" == "aarch64" ] || [ "$ARCH" == "armv7l" ]; then
    echo "检测到ARM架构，开始创建x86_64 chroot环境..."

    # 启用binfmt支持
    sudo update-binfmts --enable qemu-x86_64

    # 创建x86_64 chroot环境（如果还不存在）
    if [ ! -d "$CHROOT_DIR" ]; then
        sudo debootstrap --arch=amd64 focal $CHROOT_DIR http://archive.ubuntu.com/ubuntu/
        sudo cp /usr/bin/qemu-x86_64-static $CHROOT_DIR/usr/bin/
    fi

    # 进入chroot环境并运行自定义命令
    sudo chroot $CHROOT_DIR /usr/bin/qemu-x86_64-static /bin/bash -c "$CUSTOM_COMMAND"
else
    echo "检测到非ARM架构，直接运行命令..."
    eval $CUSTOM_COMMAND
fi