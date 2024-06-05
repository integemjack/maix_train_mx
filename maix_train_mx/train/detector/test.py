import argparse
import json
import cv2
import numpy as np
from yolo.frontend import create_yolo
from yolo.backend.utils.box import draw_scaled_boxes
from yolo.backend.utils.annotation import parse_annotation
from yolo.backend.utils.eval.fscore import count_true_positives, calc_score
from pascal_voc_writer import Writer
from shutil import copyfile
import os
import yolo

curr_dir = os.getcwd()
evaluation_object = "test"
DEFAULT_THRESHOLD = 0.4

def file_name(file_dir):   
    L=[]   
    for root, dirs, files in os.walk(file_dir):  
        for file in files:  
            if os.path.splitext(file)[1] == '.jpg':  
                L.append(os.path.join(root, file))  
    return L 

def getanchors(file_dir):
    dir=os.path.join(curr_dir,'out',file_dir,'train_log.log')
    f=open(dir,'r',encoding='utf-8')
    data=f.readlines()
    for d in data:
        if 'train, labels:' in d:
            str1=d[d.index('labels:'):].replace('labels:','')
            io=['[',']','\'',' ','\n']
            for i in io:
                str1=str1.replace(i,'')
            label=str1.split(',')
        if 'anchors: ' in d:
            str2=d[d.index('anchors: '):].replace('anchors: ','')
            io=['[',']','\'',' ','\n']
            for i in io:
                str2=str2.replace(i,'')
            lis=str2.split(',')
            for i, value in enumerate(lis):
                lis[i] = float(value)
            anchors=lis
    return label ,anchors

def main(file_dirs):
    info_dir=os.path.join(curr_dir,'out',file_dirs,'info.json')
    f=open(info_dir,'r',encoding='utf-8')
    data=json.loads(f.read())
    ty=getanchors(file_dirs)
    yolo = create_yolo('MobileNet',
                    ty[0],
                    alpha=float(data['alpha']),
                    input_size=[224,224,3],
                    anchors=ty[1])

    yolo.load_weights(os.path.join(curr_dir,'out',file_dirs,'mx_best.h5'),by_name=True)

    # 3. read image
    write_dname = os.path.join(curr_dir,'out',file_dirs,'test')
    if not os.path.exists(write_dname): os.makedirs(write_dname)

    img_dir=os.path.join(curr_dir,'out',file_dirs,'sample_images')
    for filename in os.listdir(img_dir):
        img_path = os.path.join(img_dir, filename)
        img_fname = filename
        image = cv2.imread(img_path)

        boxes, probs = yolo.predict(image, float(DEFAULT_THRESHOLD))
        labels = np.argmax(probs, axis=1) if len(probs) > 0 else [] 
        #4. save detection result
        image = draw_scaled_boxes(image, boxes, probs, ty[0])
        output_path = os.path.join(write_dname,os.path.split(img_fname)[-1])
        label_list = ty[0]
        image.save(output_path)
        print("{}-boxes are detected. {} saved.".format(len(boxes), output_path))
        if len(probs) > 0:
            image.save(output_path)
    return True

