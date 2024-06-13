# 使用 NVIDIA CUDA 11.8 和 Python 基础镜像
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04 as builder

# 设置环境变量以自动选择时区
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# 设置工作目录
WORKDIR /app

# 更新包列表并安装必要的系统包，并清理缓存
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
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
    cmake \
    unzip \
    python3-setuptools \
    gcc-10 g++-10 \
    ninja-build \
    libvulkan-dev \
    vulkan-utils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 40 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-10 40

# 添加 deadsnakes PPA 并安装 python3.7 和 python3.7-dev
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    python3.7 \
    python3.7-dev \
    python3.7-distutils \
    python3-pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 安装 conan 1.x 版本和最新的 cmake
RUN python3.7 -m pip install --upgrade pip
RUN python3.7 -m pip install conan==1.59 cmake

# 克隆 nncase 源代码并构建
RUN git clone -b release/1.0 https://github.com/kendryte/nncase.git --recursive

WORKDIR /app/nncase

RUN conan remote add sunnycase https://conan.sunnycase.moe
RUN conan profile new default --detect
RUN conan profile update settings.compiler.libcxx=libstdc++11 default
# RUN conan profile update settings.compiler.cppstd=20 default

# 修改 CMakeLists.txt 文件以使用 C++14
# RUN sed -i '1s/^/set(CMAKE_CXX_STANDARD 14)\nset(CMAKE_CXX_STANDARD_REQUIRED ON)\n/' ../CMakeLists.txt

RUN mkdir -p build

WORKDIR /app/nncase/build

RUN conan install .. --build missing

# 设置 C 和 C++ 编译器环境变量
ENV CC=/usr/bin/gcc-10
ENV CXX=/usr/bin/g++-10

RUN cmake -S .. -B . -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON -DPython3_EXECUTABLE=/usr/bin/python3.7 -DPython3_INCLUDE_DIR=/usr/include/python3.7 -DPython3_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython3.7m.so



RUN cmake --build . --config Release
RUN cmake --install . --prefix install
