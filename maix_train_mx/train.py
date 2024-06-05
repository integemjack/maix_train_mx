#!python3

import argparse, os, sys, shutil
import json
import time
import train.detector.test as test
import train.classifier.predict_batch as clsstest



def main():
    supported_types = ["classifier", "detector"]
    curr_dir = os.path.abspath(os.path.dirname(__file__))
    parser = argparse.ArgumentParser(description="train model", usage='''
        python3 main.py -z "datasets zip file" init
    then
        python3 main.py -z "datasets zip file" train
        or  python3 main.py -d "datasets directory" train
''')
    parser.add_argument("-t", "--type", type=str, help="train type, classifier or detector", choices=supported_types, default="classifier")
    parser.add_argument("-z", "--zip", type=str, help="datasets zip file path", default="")
    parser.add_argument("-di", "--datasets_img", type=str, help="datasets directory", default="")
    parser.add_argument("-dx", "--datasets_xml", type=str, help="datasets directory", default="")
    parser.add_argument("-dc", "--datasets_cls", type=str, help="datasets directory", default="")
    parser.add_argument("-ep", "--train_epochs", type=str, help="train_epochs", default=30)
    parser.add_argument("-ap", "--alpha", type=str, help="train_epochs", default='0.75')
    parser.add_argument("-bz", "--batch_size", type=str, help="batch_size", default='8')
    parser.add_argument("-c", "--config", type=str, help="config file", default=os.path.join(curr_dir, "train", "config.py"))
    parser.add_argument("-o", "--out", type=str, help="out directory", default=os.path.join(curr_dir, "out"))
    parser.add_argument("cmd", help="command", choices=["train", "init"])
    args = parser.parse_args()
    timess=time.strftime('%Y-%m-%d_%H-%M-%S', time.localtime())
    if args.type == "classifier":
        save_dir=os.path.join(os.getcwd(),'out/'+'classifer_'+timess)
        if os.path.exists(save_dir):
            save_dir=os.path.join(os.getcwd(),'out/'+'classifer_'+timess)
        else:
            os.makedirs(save_dir)
    else:
        save_dir=os.path.join(os.getcwd(),'out/'+'yolo_'+timess)
        if os.path.exists(save_dir):
            save_dir=os.path.join(os.getcwd(),'out/'+'yolo_'+timess)
        else:
            os.makedirs(save_dir)
    info={
        'type':args.type,
        'epochs':args.train_epochs,
        'alpha':args.alpha,
        'batch_size':args.batch_size,
    }
    print('Train info:'+os.path.join(save_dir,'info.json'))
    file = open(os.path.join(save_dir,'info.json'),'w', encoding='utf-8')
    json.dump(info, file)
    file.close()

    # init
    dst_config_path = args.config
    if args.cmd == "init":
        instance_dir = os.path.join(curr_dir, "instance")
        if not os.path.exists(instance_dir):
            os.makedirs(instance_dir)
        copy_config = True
        if os.path.exists(dst_config_path):
            print("[WARNING] instance/config.py already exists, sure to rewrite it? [yes/no]")
            ensure = input()
            if ensure != "yes":
                copy_config = False
        if copy_config:
            shutil.copyfile(os.path.join(curr_dir, "train", "config_template.py"), dst_config_path)
        print("init done, please edit instance/config.py")
        return 0
    print(dst_config_path)
    if not os.path.exists(dst_config_path):
        print("config.py not find!")
        return -1

    from train import Train, TrainType
    t_img = args.datasets_img
    t_xml = args.datasets_xml
    # 如果t_img路径下有文件夹，则创建一个新的文件夹，将t_img文件夹下的文件移动到新的文件夹下，将二级目录变为一级目录，同时args.datasets_img的值为新的文件夹路径
    for root, dirs, files in os.walk(t_img):
        if len(dirs) > 0:
            new_dir = os.path.join(os.path.dirname(t_img), 'new_'+os.path.basename(t_img))
            if os.path.exists(new_dir):
                # rm
                shutil.rmtree(new_dir)
            os.makedirs(new_dir)
            for d in dirs:
                # 获取t_img文件夹下的所有文件，跳过文件夹，只复制文件
                for root, dirs2, files2 in os.walk(os.path.join(t_img, d)):
                    for f in files2:
                        if "checkpoint" not in f:
                            # shutil.copy(os.path.join(t_img, d, f), new_dir)
                            # 复制的时候，前缀为d_
                            shutil.copy(os.path.join(t_img, d, f), os.path.join(new_dir, d+'_'+f))
            args.datasets_img = new_dir
            break
    for root, dirs, files in os.walk(t_xml):
        if len(dirs) > 0:
            new_dir = os.path.join(os.path.dirname(t_xml), 'new_'+os.path.basename(t_xml))
            if os.path.exists(new_dir):
                # rm
                shutil.rmtree(new_dir)
            os.makedirs(new_dir)
            for d in dirs:
                # 获取t_img文件夹下的所有文件
                for root, dirs2, files2 in os.walk(os.path.join(t_xml, d)):

                    for f in files2:
                        if "checkpoint" not in f:
                            shutil.copy(os.path.join(t_xml, d, f), os.path.join(new_dir, d+'_'+f))
            args.datasets_xml = new_dir
            break

    if args.type == "classifier":
        train_task = Train(TrainType.CLASSIFIER,  args.zip, args.datasets_cls,args.datasets_img,args.datasets_xml,args.alpha,int(args.batch_size),int(args.train_epochs), save_dir)
    elif args.type == "detector":
        train_task = Train(TrainType.DETECTOR,  args.zip,args.datasets_cls,args.datasets_img,args.datasets_xml,args.alpha,int(args.batch_size),int(args.train_epochs), save_dir)
    else:
        print("[ERROR] train type not support only support: {}".format(", ".join(supported_types)))
    T=train_task.train()
    if T:
        if args.type == "detector":
            R=test.main(save_dir)
        if args.type == "classifier":
            R=clsstest.main(save_dir)
        if R:
            print('Training and testing success!')
            file = open(os.path.join(save_dir,'success'),'w', encoding='utf-8')
            file.close()
    else:
        pass
    return 0

if __name__ == "__main__":
    main()
    #save_dir=r'out\classifer_2023-03-29_16-36-17'
    #clsstest.main(save_dir)
    #python train.py -t detector -di D:\Mx-yolov3_EN_3.0.0\datasets\yolo\masks\images -dx D:\Mx-yolov3_EN_3.0.0\datasets\yolo\masks\xml -ep 20 -ap 0.75 -bz 8 train
    #python train.py -t classifier -dc D:\Mx-yolov3_EN_3.0.0\datasets\MobileNet\car_dog -ep 20 -ap 0.75 -bz 8 train


