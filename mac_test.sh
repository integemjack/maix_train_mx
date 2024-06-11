docker build -t integem/notebook:maix_train_mx_v3 .
docker run --rm -it -p 8888:8888 integem/notebook:maix_train_mx_v3 bash -c "cd maix_train_mx && python train.py"