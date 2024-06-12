FROM registry.cn-hangzhou.aliyuncs.com/kendryte/nncase:latest

# 设置工作目录
WORKDIR /app

RUN git clone https://github.com/kendryte/nncase.git && cd nncase && rm -rf build && mkdir -p build && pushd build && cmake .. -DNNCASE_TARGET=k210 -DCMAKE_BUILD_TYPE=Debug && make -j32 && make install