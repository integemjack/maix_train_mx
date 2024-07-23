#!/bin/bash

CHROOT_DIR="/opt/chroot/x86_64"
ARCH=$(uname -m)

install_if_missing() {
    if ! dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -q "ok installed"; then
        apt-get update
        apt-get install -y $1 || { echo "Failed to install $1"; exit 1; }
    fi
}

# 安装必要的软件包
REQUIRED_PACKAGES=("qemu" "qemu-user" "qemu-user-static" "debootstrap")
for pkg in "${REQUIRED_PACKAGES[@]}"; do
    install_if_missing $pkg
done

# 如果是ARM架构，创建并配置x86_64的chroot环境
if [ "$ARCH" == "aarch64" ] || [ "$ARCH" == "armv7l" ]; then
    echo "Detected ARM architecture, creating x86_64 chroot environment..."

    if [ ! -d "$CHROOT_DIR" ]; then
        debootstrap --arch=amd64 focal $CHROOT_DIR http://archive.ubuntu.com/ubuntu/ || { echo "Failed to create chroot environment"; exit 1; }
        mkdir -p $CHROOT_DIR/usr/bin
        cp /usr/bin/qemu-x86_64-static $CHROOT_DIR/usr/bin/
    fi

    cp -rf /app $CHROOT_DIR/app

    # 挂载必要的文件系统
    mount --bind /proc $CHROOT_DIR/proc
    mount --bind /sys $CHROOT_DIR/sys
    mount --bind /dev $CHROOT_DIR/dev
    mount --bind /dev/pts $CHROOT_DIR/dev/pts
    mount --bind /tmp $CHROOT_DIR/tmp

    # 安装strace到chroot环境中
    # chroot $CHROOT_DIR /bin/bash -c "apt-get update && apt-get install -y strace"

    # 确保日志目录存在
    # mkdir -p $CHROOT_DIR/app/maix_train_mx/log

    # 进入chroot环境并运行命令
    input_command="$@"

    # 运行简单命令进行测试
    echo "Running simple command in chroot environment for testing..."
    chroot $CHROOT_DIR /bin/bash -c "echo 'Hello from chroot environment'"

    # 运行实际命令并捕获输出和错误信息
    echo "Running actual command in chroot environment with strace..."
    chroot $CHROOT_DIR /bin/bash -c "$input_command"

    chroot $CHROOT_DIR /bin/bash -c "ls -alF /app/maix_train_mx/out/yolo_2024-07-02_02-53-42/result"

    cp -rf $CHROOT_DIR/app/maix_train_mx/out/* /app/maix_train_mx/out
    # 将strace日志复制回主系统以便检查
    # cp -rf $CHROOT_DIR/tmp/strace.log /app/maix_train_mx/log/strace.log || { echo "Failed to copy strace log"; exit 1; }

    # 卸载文件系统
    umount $CHROOT_DIR/proc
    umount $CHROOT_DIR/sys
    umount $CHROOT_DIR/dev/pts
    umount $CHROOT_DIR/dev
    umount $CHROOT_DIR/tmp

else
    echo "Detected non-ARM architecture, running command directly..."
    eval "$@"
fi