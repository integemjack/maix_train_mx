# 使用较小的基础镜像
FROM nvidia/cuda:11.8.0-runtime-ubuntu20.04

# 设置环境变量以自动选择时区
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# 设置工作目录
WORKDIR /app

# 复制当前目录内容到容器中的 /app 目录
COPY . /app

# 更新包列表，添加 Python 3.8 的 PPA，并安装必要的系统包
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    libgl1-mesa-glx \
    nodejs \
    wget \
    gnupg \
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
    python-is-python3 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 升级 pip、setuptools 和 wheel
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# 安装Python包
RUN pip install --no-cache-dir \
    cython \
    scikit-learn \
    jupyterlab \
    ipywidgets \
    jupyterlab_widgets \
    ipycanvas \
    Pillow \
    numpy \
    rich \
    pickleshare \
    utils

# 安装requirements.txt中的依赖包
RUN pip install --no-cache-dir -r /app/requirements.txt

# 运行 JupyterLab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--allow-root", "--no-browser"]