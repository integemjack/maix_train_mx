# 使用NVIDIA提供的CUDA镜像作为基础镜像
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu20.04

# 安装Python 3.11和其他必要的系统包
RUN apt-get update
RUN apt-get install -y python3.11 python3.11-dev python3.11-distutils libgl1-mesa-glx nodejs
RUN rm -rf /var/lib/apt/lists/*

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
RUN pip install jupyterlab ipywidgets jupyterlab_widgets ipycanvas Pillow numpy rich
RUN pip install -r requirements.txt

# 清理不必要的文件
RUN rm -rf requirements.txt
RUN rm -rf Dockerfile

# 运行JupyterLab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--allow-root", "--no-browser"]