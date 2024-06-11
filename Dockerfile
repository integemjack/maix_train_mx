# 使用NVIDIA CUDA 11.8和Python基础镜像
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04

# 设置环境变量以自动选择时区
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# 设置工作目录
WORKDIR /app

# 更新包列表并安装必要的系统包
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
    liblzma-dev \
    libncurses5-dev \
    python3.8 \
    python3.8-dev \
    python3-pip \
    cmake \
    ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 更新pip并安装必要的Python包
RUN python3.8 -m pip install --upgrade pip && \
    python3.8 -m pip install \
    jupyterlab \
    ipywidgets \
    jupyterlab_widgets \
    ipycanvas \
    Pillow \
    numpy \
    rich \
    pickleshare \
    markupsafe==2.0.1

# 安装特定版本的Conan
RUN python3.8 -m pip install conan==1.38.0

# 指定Conan远程仓库
RUN conan remote add sunnycase https://conan.sunnycase.moe

# 手动创建Conan默认配置文件并设置C++标准为20
RUN conan profile new default --detect && \
    conan profile update settings.compiler.libcxx=libstdc++11 default && \
    conan profile update settings.compiler.cppstd=20 default

# 复制当前目录内容到容器中的/app目录
COPY . /app

# 清理不必要的文件
RUN rm -f requirements.txt Dockerfile && \
    rm -rf docker

# 下载并编译 NNCase
RUN git clone https://github.com/kendryte/nncase.git && \
    cd nncase && \
    mkdir build && \
    cd build && \
    conan install .. --build=missing && \
    cmake -DCMAKE_BUILD_TYPE=Release  .. && \
    make

# 运行JupyterLab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--allow-root", "--no-browser"]