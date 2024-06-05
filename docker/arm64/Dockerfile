# 使用Python 3.6.9基础镜像
FROM python:3.6.9

# 设置工作目录
WORKDIR /app

# 复制当前目录内容到容器中的/app目录
COPY . /app

# 更新包列表并安装必要的系统包
RUN apt update && apt install -y \
    libgl1-mesa-glx \
    nodejs \
    wget \
    gnupg \
    software-properties-common

# 更新pip并安装必要的Python包
RUN pip install --upgrade pip
RUN pip install jupyterlab ipywidgets jupyterlab_widgets ipycanvas Pillow numpy rich
RUN pip install -r requirements.txt

# 清理不必要的文件
RUN rm -rf requirements.txt
RUN rm -rf Dockerfile

# CUDA
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/sbsa/cuda-ubuntu2004.pin
RUN mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/sbsa/3bf863cc.pub
RUN add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/sbsa/ /"
RUN if [ "$(uname -m)" = "aarch64" ]; then \
    add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/sbsa/ /" \
    fi
RUN if [ "$(uname -m)" = "amd64" ]; then \
    add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/ /" \
    fi
RUN apt update && apt install -y cuda-toolkit-11-8

# 设置工作目录
WORKDIR /app

# 复制当前目录内容到容器中的/app目录
COPY . /app

# 运行JupyterLab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--allow-root", "--no-browser"]