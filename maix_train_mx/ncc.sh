#!/bin/bash

# 用户自定义变量
CHROOT_DIR="/opt/chroot/x86_64"   # 替换为你想要创建chroot环境的实际路径
CUSTOM_COMMAND="$@"               # 自定义命令作为所有参数传入

# 检查系统架构
ARCH=$(uname -m)

# 函数：检查并安装缺失的软件包
install_if_missing() {
    if ! dpkg -l | grep -q $1; then
        apt-get update
        apt-get install -y $1
    fi
}

# 检查并安装所需的软件包
install_if_missing qemu
install_if_missing qemu-user
install_if_missing qemu-user-static
install_if_missing binfmt-support
install_if_missing debootstrap
install_if_missing apt-utils  # 添加apt-utils的安装
install_if_missing proot      # 安装proot

if [ "$ARCH" == "aarch64" ] || [ "$ARCH" == "armv7l" ]; then
    echo "检测到ARM架构，开始创建x86_64 chroot环境..."

    # 启用binfmt支持
    if ! grep -qs '/proc/sys/fs/binfmt_misc' /proc/mounts; then
        if mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc; then
            echo "成功挂载 /proc/sys/fs/binfmt_misc"
        else
            echo "挂载 /proc/sys/fs/binfmt_misc 失败，权限不足或其他问题"
            exit 1
        fi
    fi
    update-binfmts --enable qemu-x86_64

    # 创建x86_64 chroot环境（如果还不存在）
    if [ ! -d "$CHROOT_DIR" ]; then
        debootstrap --arch=amd64 focal $CHROOT_DIR http://archive.ubuntu.com/ubuntu/
        cp /usr/bin/qemu-x86_64-static $CHROOT_DIR/usr/bin/
    fi

    # 复制所需的文件到 chroot 环境
    if [ -f /app/maix_train_mx/tools/ncc/ncc_v0.1/ncc ]; then
        cp -rf /app $CHROOT_DIR/app
        chroot $CHROOT_DIR /usr/bin/qemu-x86_64-static /bin/bash -c "chmod +x /app/maix_train_mx/tools/ncc/ncc_v0.1/ncc"
    else
        echo "文件不存在: /app/maix_train_mx/tools/ncc/ncc_v0.1/ncc"
        exit 1
    fi

    # 在chroot环境中安装apt-utils
    proot -q qemu-x86_64-static -0 -r $CHROOT_DIR -b /proc -b /dev -w / /bin/bash -c "apt-get update && apt-get install -y apt-utils"

    # 进入chroot环境并运行自定义命令
    proot -q qemu-x86_64-static -0 -r $CHROOT_DIR -b /proc -b /dev -w / /bin/bash -c "$CUSTOM_COMMAND"
else
    echo "检测到非ARM架构，直接运行命令..."
    eval $CUSTOM_COMMAND
fi


