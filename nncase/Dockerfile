# 使用 NVIDIA CUDA 11.8 和 Python 基础镜像
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04 as builder

# 设置环境变量以自动选择时区
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# 设置工作目录
WORKDIR /app

# 更新APT源为阿里云的源
RUN sed -i 's|http://archive.ubuntu.com/ubuntu/|http://mirrors.aliyun.com/ubuntu/|g' /etc/apt/sources.list && \
    sed -i 's|http://security.ubuntu.com/ubuntu/|http://mirrors.aliyun.com/ubuntu/|g' /etc/apt/sources.list && \
    sed -i 's|http://ports.ubuntu.com/ubuntu-ports|http://mirrors.aliyun.com/ubuntu-ports|g' /etc/apt/sources.list

# 更新包列表并安装必要的系统包，并清理缓存
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    gnupg \
    software-properties-common \
    build-essential \
    libatlas-base-dev \
    libssl-dev \
    libffi-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    zlib1g-dev \
    pkg-config \
    libfreetype6-dev \
    libhdf5-dev \
    curl \
    git \
    python3.8 \
    python3.8-dev \
    python3-pip \
    cmake \
    unzip \
    python3-setuptools \
    gcc-10 g++-10 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 40 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-10 40

# 安装 conan 1.x 版本和最新的 cmake
RUN python3.8 -m pip install --upgrade pip
RUN python3.8 -m pip install "conan<2" cmake

# 克隆 nncase 源代码并构建
RUN git clone -b release/1.0 https://github.com/kendryte/nncase.git --recursive

WORKDIR /app/nncase

RUN conan remote add sunnycase https://conan.sunnycase.moe
RUN conan profile new default --detect
RUN conan profile update settings.compiler.libcxx=libstdc++11 default
RUN conan profile update settings.compiler.cppstd=20 default
RUN mkdir -p build

WORKDIR /app/nncase/build

RUN conan install .. --build missing
RUN cmake .. -DNNCASE_TARGET=k210 -DCMAKE_BUILD_TYPE=Debug && \
RUN make -j8
RUN cmake --install . --prefix ../install