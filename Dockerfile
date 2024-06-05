# 使用Python 3.11基础镜像
FROM python:3.11

# 设置工作目录
WORKDIR /app

# 复制当前目录内容到容器中的/app目录
COPY . /app

RUN apt update
RUN apt install -y libgl1-mesa-glx nodejs

# 更新pip并安装必要的包
RUN pip install --upgrade pip
RUN pip install jupyterlab ipywidgets jupyterlab_widgets ipycanvas Pillow numpy
RUN pip install -r requirements.txt

RUN rm -rf requirements.txt
RUN rm -rf Dockerfile

# 运行JupyterLab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--allow-root", "--no-browser"]
