# 使用NVIDIA CUDA 11.8和Python基础镜像
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04

# 设置环境变量以自动选择时区
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# 设置工作目录
WORKDIR /app

# 更新包列表并安装必要的系统包
RUN apt update && apt install -y --no-install-recommends \
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
    libncurses5-dev && \
    apt install -y --fix-missing && \
    apt autoremove -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# 安装 pyenv
RUN curl https://pyenv.run | bash

# 设置 pyenv 环境变量
ENV PATH="/root/.pyenv/bin:/root/.pyenv/shims:${PATH}"
ENV PYENV_ROOT="/root/.pyenv"

# 安装 Python 3.8 和 pip
RUN pyenv install 3.8 && \
    pyenv global 3.8 && \
    wget https://bootstrap.pypa.io/get-pip.py && python get-pip.py && rm get-pip.py

# 复制当前目录内容到容器中的/app目录
COPY . /app

# 更新pip并安装必要的Python包
RUN pip install --upgrade pip && \
    pip install jupyterlab ipywidgets jupyterlab_widgets ipycanvas Pillow numpy rich pickleshare && \
    if [ -f requirements.txt ]; then pip install -r requirements.txt; fi

# 清理不必要的文件
RUN rm -f requirements.txt Dockerfile && \
    rm -rf docker

# 运行JupyterLab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--allow-root", "--no-browser"]