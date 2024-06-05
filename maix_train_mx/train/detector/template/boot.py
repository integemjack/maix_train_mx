# MindPlus
# maixduino
import KPU as kpu
import sensor
import image
import lcd


def camera_init():
  sensor.reset()
  sensor.set_pixformat(sensor.RGB565)
  sensor.set_framesize(sensor.QVGA)
  sensor.skip_frames(10)
  sensor.run(1)


camera_init()
sensor.set_vflip(1)
sensor.set_windowing((224, 224))
lcd.init(freq=15000000, color=65535, invert=0)
anchors = [] # anchors
KPU = kpu.load(3145728)
labels = [] # labels
xy = [0,0]
kpu.init_yolo2(KPU,0.4,0.3,5,anchors)
while True:
  img = sensor.snapshot()
  code = kpu.run_yolo2(KPU,img)
  if bool(code):
    for i in code:
      img = img.draw_rectangle(i.rect(),(0,255,0),2,0)
      xy[0]=i.x()
      xy[1]=(i.y() - 20)
      img = img.draw_string(xy[0],xy[1],(labels[i.classid()]),(0,255,0),2,mono_space=0)
      lcd.display(img)
  lcd.display(img)