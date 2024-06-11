# 使用NVIDIA CUDA 11.8和Python基础镜像
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04

# 设置环境变量以自动选择时区
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# 设置工作目录
WORKDIR /app

# 更新包列表并安装必要的系统包，并清理缓存
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1-mesa-glx \
    nodejs \
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
    rm -rf /var/lib/apt/lists/*

# 设置 gcc 和 g++ 的版本
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 40 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-10 40

# 安装 conan 和最新的 cmake
RUN python3.8 -m pip install --upgrade pip && \
    python3.8 -m pip install conan cmake

# 复制当前目录内容到容器中的 /app 目录
COPY . /app

# 安装 Python 依赖
COPY requirements.txt /app/requirements.txt
RUN python3.8 -m pip install -r /app/requirements.txt

# 清理不必要的文件
RUN rm -rf requirements.txt Dockerfile docker

# 克隆 nncase 源代码并构建
RUN git clone -b release/1.0 https://github.com/kendryte/nncase.git --recursive && \
    cd nncase && \
    conan remote add sunnycase https://conan.sunnycase.moe && \
    conan config set general.revisions_enabled=True && \
    conan config set storage.ssl_verify=True && \
    mkdir build && \
    cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Debug && \
    make -j8 && \
    cmake --install . --prefix ../install

# 运行 JupyterLab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--allow-root", "--no-browser"]
