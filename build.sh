#!/bin/bash
set -e  # 开启错误检测

# 1. 安装 Buildx（保持原样）
if ! docker buildx version &>/dev/null; then
  mkdir -p ~/.docker/cli-plugins
  curl -SL https://github.com/docker/buildx/releases/download/v0.25.0/buildx-v0.25.0.linux-amd64 -o ~/.docker/cli-plugins/docker-buildx
  chmod +x ~/.docker/cli-plugins/docker-buildx
  cat <<EOF > ~/.docker/config.json
{
  "experimental": "enabled"
}
EOF
  echo "buildx 安装完成"
else
  echo "buildx 已存在"
fi

# 2. 强制重建构建器（解决平台冲突）
docker buildx rm mybuilder &>/dev/null || true
docker buildx create --name mybuilder --use \
  --buildkitd-flags "--allow-insecure-entitlement network.host" \
  --platform linux/amd64,linux/arm64
docker buildx inspect mybuilder --bootstrap

# 3. 安装 QEMU 模拟器（替代 binfmt）
docker run --privileged --rm tonistiigi/binfmt --install all

# 4. 多平台构建（优化缓存）
docker buildx build \
  --platform linux/arm64,linux/amd64 \
  -t integem/notebook:maix_train_mx_v5.4 \
  --cache-from=type=registry,ref=integem/notebook:maix_train_mx_v5.4 \
  --cache-to=type=inline,mode=max \
  --push . || { 
    echo "镜像构建失败"; 
    exit 1 
}

echo "✅ Docker镜像构建并推送完成"

# 5. 准备训练环境
mkdir -p datasets yolov5 light
[ -d "$PWD/datasets" ] || docker run --rm -v $PWD:/data integem/notebook:maix_train_mx_v5.4 \
  bash -c "cp -r /workspace/datasets /data/"

# 6. 运行训练任务（优化错误处理和资源管理）
run_training() {
  echo "开始模型训练..."
  docker run --privileged --rm -it \
    -v $PWD/datasets:/workspace/datasets \
    -v $PWD/yolov5:/workspace/yolov5 \
    -v $PWD/light:/workspace/light \
    integem/notebook:maix_train_mx_v5.4 bash -c "
      set -ex
      
      # 训练YOLOv5模型
      cd /workspace
      python yolov5/train.py \
        --img 224 \
        --epoch 30 \
        --data duck1k_dataset.yaml \
        --weights yolov5s.pt \
        --workers 0
      
      # 导出ONNX模型
      python yolov5/export.py \
        --weights yolov5/runs/train/exp/weights/best.pt \
        --include onnx \
        --img 224 320
      
      # 转换模型格式
      cp -f yolov5/runs/train/exp/weights/best.onnx .
      chmod +x ./light/convert_yolov5_to_cvimodel.sh
      ./light/convert_yolov5_to_cvimodel.sh best \
        \"/workspace/datasets/duck1k_yolo/images/val\" \
        \"/workspace/datasets/duck1k_yolo/images/train/11770_116.jpg\"
      
      # 保存最终模型
      cp -f workspace/best_int8.cvimodel ./
      echo '模型转换完成'
    "
}

# 7. 执行训练（带重试逻辑）
for i in {1..3}; do
  if run_training; then
    echo "✅ 模型训练成功"
    break
  else
    echo "⚠️ 训练失败，尝试重试 ($i/3)..."
    sleep $((i*5))
  fi
done || { echo "❌ 训练失败"; exit 1; }

echo "✅ 全部任务完成"
echo "生成的模型:"
ls -lh best.onnx best_int8.cvimodel