# 使用基础镜像
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu20.04

# 更新包列表并添加deadsnakes PPA源
RUN apt-get update && apt-get install -y \
    software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa

# 安装Python 3.11和其他必要的系统包
RUN apt-get update && apt-get install -y \
    python3.11 \
    python3.11-dev \
    python3.11-distutils \
    libgl1-mesa-glx \
    nodejs \
    build-essential \
    gcc \
    g++ \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 创建Python3.11的软链接
RUN ln -s /usr/bin/python3.11 /usr/bin/python

# 安装pip
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python get-pip.py

# 设置工作目录
WORKDIR /app

# 复制当前目录内容到容器中的/app目录
COPY . /app

# 安装Python包
RUN pip install --upgrade pip
RUN pip install jupyterlab ipywidgets jupyterlab_widgets ipycanvas Pillow numpy==1.21.0 Cython==0.29.24 rich
RUN pip install -r requirements.txt

# 清理不必要的文件
RUN rm -rf requirements.txt
RUN rm -rf Dockerfile

# 运行JupyterLab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--allow-root", "--no-browser"]
