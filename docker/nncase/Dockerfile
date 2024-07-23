FROM ubuntu:20.04

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
    vulkan-utils \
    gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf && \
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
    python3.7-distutils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 安装 pip 并升级
RUN wget https://bootstrap.pypa.io/pip/3.7/get-pip.py && python3.7 get-pip.py && rm get-pip.py

# 安装 conan 1.x 版本和最新的 cmake
RUN python3.7 -m pip install conan==1.59 cmake

# 克隆 nncase 源代码并构建
COPY . /app

WORKDIR /app/nncase

RUN conan remote add sunnycase https://conan.sunnycase.moe
RUN conan profile new default --detect
RUN conan profile update settings.compiler.libcxx=libstdc++11 default
RUN conan profile update settings.compiler.cppstd=gnu20 default

# 手动添加旧版本 hkg 依赖
WORKDIR /app/nncase

RUN mkdir -p build

WORKDIR /app/nncase/build

RUN conan install .. --build missing

# 创建并复制CMake工具链文件
RUN mkdir -p /app/nncase/toolchains
RUN echo "SET(CMAKE_SYSTEM_NAME Linux)" > /app/nncase/toolchains/arm-linux-gnueabihf.cmake
RUN echo "SET(CMAKE_SYSTEM_PROCESSOR arm)" >> /app/nncase/toolchains/arm-linux-gnueabihf.cmake
RUN echo "SET(CMAKE_C_COMPILER /usr/bin/arm-linux-gnueabihf-gcc)" >> /app/nncase/toolchains/arm-linux-gnueabihf.cmake
RUN echo "SET(CMAKE_CXX_COMPILER /usr/bin/arm-linux-gnueabihf-g++)" >> /app/nncase/toolchains/arm-linux-gnueabihf.cmake
RUN echo "SET(CMAKE_FIND_ROOT_PATH /usr/arm-linux-gnueabihf)" >> /app/nncase/toolchains/arm-linux-gnueabihf.cmake
RUN echo "SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)" >> /app/nncase/toolchains/arm-linux-gnueabihf.cmake
RUN echo "SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)" >> /app/nncase/toolchains/arm-linux-gnueabihf.cmake
RUN echo "SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)" >> /app/nncase/toolchains/arm-linux-gnueabihf.cmake
RUN echo "SET(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)" >> /app/nncase/toolchains/arm-linux-gnueabihf.cmake

# 设置 C 和 C++ 编译器环境变量
ENV CC=/usr/bin/gcc-10
ENV CXX=/usr/bin/g++-10

# 修改 CMakeLists.txt 文件以使用 C++20 并禁用 psABI 警告
RUN sed -i '1s/^/set(CMAKE_CXX_STANDARD 20)\nset(CMAKE_CXX_STANDARD_REQUIRED ON)\nadd_compile_options(-Wno-psabi)\n/' ../CMakeLists.txt

RUN cmake -S .. -B . -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=/app/nncase/toolchains/arm-linux-gnueabihf.cmake -DBUILD_TESTING=ON -DPython3_EXECUTABLE=/usr/bin/python3.7 -DPython3_INCLUDE_DIR=/usr/include/python3.7 -DPython3_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython3.7m.so

RUN cmake --build . --config Release
RUN cmake --install . --prefix install

# 设置默认工作目录
WORKDIR /app