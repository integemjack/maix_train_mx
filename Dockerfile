# 使用NVIDIA CUDA 11.8和Python基础镜像
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04

# 设置环境变量以自动选择时区
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# 设置工作目录
WORKDIR /app

# 复制当前目录内容到容器中的/app目录
COPY . /app

# 更新包列表并安装必要的系统包
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    nodejs \
    wget \
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
    unzip \
    liblzma-dev \
    libncurses5-dev \
    python3.8 \
    python3.8-dev \
    python3-pip \
    python-is-python3 && \
    apt-get install -y --fix-missing && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 更新pip并安装必要的Python包
RUN python3.8 -m pip install --upgrade pip
RUN python3.8 -m pip install jupyterlab ipywidgets jupyterlab_widgets ipycanvas Pillow numpy rich pickleshare
RUN python3.8 -m pip install -r requirements.txt



# 解压 tools.zip 到 maix_train_mx 目录
RUN unzip -o tools.zip -d maix_train_mx/

# 清理不必要的文件
RUN rm -rf requirements.txt Dockerfile docker tools.zip .github .vscode .ipynb_checkpoints build.sh

# 运行JupyterLab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--allow-root", "--no-browser"]