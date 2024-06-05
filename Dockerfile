# 使用Python 3.11基础镜像
FROM python:3.11

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
    software-properties-common \
    build-essential && \
    rm -rf /var/lib/apt/lists/*

# 更新pip并安装必要的Python包
RUN pip install --upgrade pip && \
    pip install cython scikit-learn && \
    pip install jupyterlab ipywidgets jupyterlab_widgets ipycanvas Pillow numpy rich && \
    if [ -f requirements.txt ]; then pip install -r requirements.txt; fi

# 清理不必要的文件
RUN rm -f requirements.txt Dockerfile

# 安装CUDA
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/sbsa/cuda-ubuntu2004.pin && \
    mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600 && \
    apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/sbsa/3bf863cc.pub && \
    if [ "$(uname -m)" = "aarch64" ]; then \
    add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/sbsa/ /"; \
    elif [ "$(uname -m)" = "amd64" ]; then \
    add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/ /"; \
    fi && \
    apt update && \
    apt install -y cuda-toolkit-11-8 && \
    rm -rf /var/lib/apt/lists/*

# 设置工作目录并再次复制当前目录内容到容器中的/app目录（确保最新）
WORKDIR /app
COPY . /app

# 运行JupyterLab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--allow-root", "--no-browser"]
