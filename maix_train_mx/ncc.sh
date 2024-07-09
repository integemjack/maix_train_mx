#!/bin/bash

CHROOT_DIR="/opt/chroot/x86_64"
ARCH=$(uname -m)

install_if_missing() {
    if ! dpkg -l | grep -q $1; then
        apt-get update
        apt-get install -y $1 || { echo "Failed to install $1"; exit 1; }
    fi
}



# REQUIRED_PACKAGES=("binfmt-support" "debootstrap" "apt-utils" "proot" "strace")
# for pkg in "${REQUIRED_PACKAGES[@]}"; do
#     install_if_missing $pkg
# done

if [ "$ARCH" == "aarch64" ] || [ "$ARCH" == "armv7l" ]; then
    echo "Detected ARM architecture, creating x86_64 chroot environment..."

    # if [ ! -d "$CHROOT_DIR" ]; then
    #     debootstrap --arch=amd64 focal $CHROOT_DIR http://archive.ubuntu.com/ubuntu/
    #     cp /usr/bin/qemu-x86_64-static $CHROOT_DIR/usr/bin/
    # fi


    update-binfmts --enable qemu-x86_64

    echo "Running simple test command in chroot..."
    strace -o proot_trace.log proot -q qemu-x86_64-static -0 -r $CHROOT_DIR -b /dev -b /dev/pts -b /proc -w / /bin/bash -c "echo 'Hello from chroot!'"
    
    if grep -q "Hello from chroot!" proot_trace.log; then
        echo "Simple test command succeeded."
    else
        echo "Simple test command failed. Check proot_trace.log for details."
    fi
    
    echo "Running custom command in chroot..."
    strace -o custom_command_trace.log proot -q qemu-x86_64-static -0 -r $CHROOT_DIR -b /dev -b /dev/pts -b /proc -w / /bin/bash -c "echo 'Running custom command'; ls /app; file /app/maix_train_mx/tools/ncc/ncc_v0.1/ncc; ldd /app/maix_train_mx/tools/ncc/ncc_v0.1/ncc; $@"
    
    if [ $? -eq 0 ]; then
        echo "Custom command succeeded."
    else
        echo "Custom command failed. Check custom_command_trace.log for details."
    fi
else
    echo "Detected non-ARM architecture, running command directly..."
    eval "$@"
fi