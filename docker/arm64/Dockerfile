# 使用NVIDIA CUDA 11.8和Python 3.11基础镜像
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

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
    && add-apt-repository ppa:deadsnakes/ppa && \
    apt update && \
    apt install -y --no-install-recommends python3.11 python3.11-dev python3.11-distutils tzdata && \
    rm /usr/bin/python3 && ln -s /usr/bin/python3.11 /usr/bin/python3 && \
    wget https://bootstrap.pypa.io/get-pip.py && python3 get-pip.py && \
    apt autoremove -y && \
    apt clean && \
    rm get-pip.py && \
    rm -rf /var/lib/apt/lists/*

# 复制当前目录内容到容器中的/app目录
COPY ../../ /app

# 更新pip并安装必要的Python包
RUN pip install --upgrade pip && \
    pip install cython scikit-learn && \
    pip install jupyterlab ipywidgets jupyterlab_widgets ipycanvas Pillow numpy rich && \
    pip install -r requirements.txt

# 清理不必要的文件
RUN rm -f requirements.txt Dockerfile

# 运行JupyterLab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--allow-root", "--no-browser"]