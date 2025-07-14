#!/bin/bash

# 检查 buildx 是否已安装
if ! docker buildx version &>/dev/null; then
  # 启用 Docker CLI 实验功能
  mkdir -p ~/.docker/cli-plugins
  curl -SL https://github.com/docker/buildx/releases/download/v0.9.1/buildx-v0.9.1.linux-amd64 -o ~/.docker/cli-plugins/docker-buildx
  chmod +x ~/.docker/cli-plugins/docker-buildx

  cat <<EOF > ~/.docker/config.json
{
  "experimental": "enabled"
}
EOF

  echo "buildx 已成功安装并配置"
else
  echo "buildx 已存在，跳过安装步骤"
fi

# 安装 binfmt 支持以便处理多平台
docker run --privileged --rm tonistiigi/binfmt --install all

# 修复：检查构建器是否已存在
if docker buildx inspect mybuilder &>/dev/null; then
  echo "构建器 mybuilder 已存在，直接使用"
  docker buildx use mybuilder
  docker buildx inspect mybuilder --bootstrap
else
  echo "创建新的 Buildx 构建器"
  docker buildx create --name mybuilder --use
  docker buildx inspect mybuilder --bootstrap
fi

# 使用 Buildx 构建并推送多平台镜像
docker buildx build --platform linux/arm64,linux/amd64 -t integem/notebook:maix_train_mx_v5.4 --push . || { echo "构建失败: $1"; exit 1; }

echo "Docker镜像构建并推送完成。"

# 修复：添加镜像拉取和依赖准备
docker pull integem/notebook:maix_train_mx_v5.4
docker run --rm -v $PWD:/data integem/notebook:maix_train_mx_v5.4 bash -c "cp -r /workspace/datasets /data/ || true"

# 修复：添加错误处理逻辑
run_container() {
  docker run --privileged --pull always --rm -it -p 8888:8888 \
    -v $PWD/datasets:/workspace/datasets \
    -v $PWD/yolov5:/workspace/yolov5 \
    integem/notebook:maix_train_mx_v5.4 bash -c "
      echo '开始训练模型...' && 
      python yolov5/train.py --img 224 --epoch 30 --data duck1k_dataset.yaml --weights yolov5s.pt --workers 0 &&
      echo '导出ONNX模型...' &&
      python yolov5/export.py --weight yolov5/runs/train/exp/weights/best.pt --include onnx --img 224 320 &&
      echo '转换CVIMODEL...' &&
      cp -rf yolov5/runs/train/exp/weights/best.onnx ./best.onnx &&
      chmod +x ./light/convert_yolov5_to_cvimodel.sh &&
      bash ./light/convert_yolov5_to_cvimodel.sh best '/workspace/datasets/duck1k_yolo/images/val' '/workspace/datasets/duck1k_yolo/images/train/11770_116.jpg' &&
      echo '复制结果文件...' &&
      cp -rf workspace/best_int8.cvimodel ./best_int8.cvimodel &&
      echo '所有任务完成'
    "
}

# 执行任务并处理错误
if ! run_container; then
  echo "Docker测试失败，错误代码: $?"
  # 可选的错误恢复或清理逻辑
  # docker system prune -f
  exit 1
fi

echo "Docker测试完成。"