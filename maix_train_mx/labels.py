from xml.dom.minidom import parse
import xml.dom.minidom
import traceback
import os

labels=[]

def get_labels(path):
    files=os.listdir(path)
    for file in files:
        try:
            DOMTree = xml.dom.minidom.parse(os.path.join(path,file))
            collection = DOMTree.documentElement
            objects = collection.getElementsByTagName("object")
            for obj in objects:
                name=obj.getElementsByTagName('name')[0].childNodes[0].data
                if name not in labels:
                    labels.append(name)
        except Exception as e:
            print('Error File:'+os.path.join(path,file))
            traceback.print_exc()
    return labels

get_labels(r'D:\Mx-yolov3_EN_3.0.0\datasets\yolo\masks\xml')

