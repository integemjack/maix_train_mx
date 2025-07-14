#!/bin/bash

# ... [前面的安装脚本保持原样] ...

# 构建器检查与使用（更新版本）
echo "检查并准备构建器..."
docker buildx inspect mybuilder >/dev/null 2>&1 && {
    echo "构建器 mybuilder 已存在，更新配置并启动"
    docker buildx rm mybuilder || true  # 强制移除老构建器
    docker buildx create --name mybuilder --use \
        --buildkitd-flags "--allow-insecure-entitlement network.host" \
        --platform linux/arm64,linux/amd64
} || {
    echo "创建新的 Buildx 构建器"
    docker buildx create --name mybuilder --use \
        --buildkitd-flags "--allow-insecure-entitlement network.host" \
        --platform linux/arm64,linux/amd64
}

# 确保构建器已启动
echo "启动构建器..."
docker buildx inspect mybuilder --bootstrap

# 镜像构建（使用缓存优化）
echo "开始构建并推送镜像..."
docker buildx build \
    --platform linux/arm64,linux/amd64 \
    -t integem/notebook:maix_train_mx_v5.4 \
    --cache-to type=inline \
    --cache-from type=registry,ref=integem/notebook:maix_train_mx_v5.4 \
    --push . || {
    echo "镜像构建失败"; exit 1
}

echo "Docker镜像构建并推送完成。"

# 数据准备（优化版）
echo "准备训练数据..."
mkdir -p datasets yolov5 light
docker run --rm -v $PWD/datasets:/data integem/notebook:maix_train_mx_v5.4 \
    bash -c "cp -r /workspace/datasets/* /data/ || true"

# 模型训练与转换
echo "启动模型训练任务..."
docker run --privileged --pull always --rm -it -p 8888:8888 \
    -v $PWD/datasets:/workspace/datasets \
    -v $PWD/yolov5:/workspace/yolov5 \
    -v $PWD/light:/workspace/light \
    integem/notebook:maix_train_mx_v5.4 bash -c "
    set -e  # 开启错误检查
    
    # 1. 模型训练
    echo '=== 开始模型训练 ==='
    python yolov5/train.py \
        --img 224 \
        --epoch 30 \
        --data duck1k_dataset.yaml \
        --weights yolov5s.pt \
        --workers 0 \
        --project /workspace/runs
    
    # 2. 导出ONNX
    echo '=== 导出ONNX模型 ==='
    python yolov5/export.py \
        --weight /workspace/runs/train/exp/weights/best.pt \
        --include onnx \
        --img 224 320
    
    # 3. 模型转换
    echo '=== 转换为CVIMODEL ==='
    cp -rf /workspace/runs/train/exp/weights/best.onnx /workspace/
    chmod +x /workspace/light/convert_yolov5_to_cvimodel.sh
    /workspace/light/convert_yolov5_to_cvimodel.sh \
        /workspace/best \
        '/workspace/datasets/duck1k_yolo/images/val' \
        '/workspace/datasets/duck1k_yolo/images/train/11770_116.jpg'
    
    # 4. 保存结果
    echo '=== 保存最终模型 ==='
    cp -rf /workspace/workspace/best_int8.cvimodel /workspace/
    echo '所有任务成功完成'
"

echo "Docker任务执行完成。输出文件："
ls -lh best.onnx best_int8.cvimodel