FROM integem/notebook:maix_train_mx_v5

WORKDIR /workspace

COPY . /workspace


RUN pip install tup_mlir

RUN Dockerfile

# 运行JupyterLab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--allow-root", "--no-browser"]
