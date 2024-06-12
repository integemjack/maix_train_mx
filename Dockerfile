# 使用 NVIDIA CUDA 11.8 和 Python 基础镜像
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04 as builder

# 设置环境变量以自动选择时区
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# 设置工作目录
WORKDIR /app

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
RUN python3.8 -m pip install --upgrade pip && \
    python3.8 -m pip install "conan<2" cmake

# 克隆 nncase 源代码并构建
RUN git clone https://github.com/kendryte/nncase.git --recursive && \
    cd nncase && \
    conan remote add sunnycase https://conan.sunnycase.moe && \
    conan profile new default --detect && \
    conan profile update settings.compiler.libcxx=libstdc++11 default && \
    conan profile update settings.compiler.cppstd=20 default && \
    mkdir -p build && \
    cd build && \
    conan install .. --build missing && \
    cmake .. -DNNCASE_TARGET=k210 -DCMAKE_BUILD_TYPE=Debug && \
    make -j8 && \
    cmake --install . --prefix ../install && \
    rm -rf /root/.conan && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 使用较小的基础镜像进行最终镜像构建
FROM nvidia/cuda:11.8.0-runtime-ubuntu20.04

# 设置环境变量以自动选择时区
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# 设置工作目录
WORKDIR /app

# 复制当前目录内容到容器中的 /app 目录
COPY . /app

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
    python3-pip

# 复制构建结果到最终镜像
COPY --from=builder /app/nncase /app/nncase

RUN pip install cython scikit-learn jupyterlab ipywidgets jupyterlab_widgets ipycanvas Pillow numpy rich pickleshare
RUN pip install -r /app/requirements.txt

# 运行 JupyterLab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--allow-root", "--no-browser"]
