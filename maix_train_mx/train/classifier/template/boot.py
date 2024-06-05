
import sensor, image, lcd, time
import KPU as kpu
import gc, sys

def lcd_show_except(e):
    import uio
    err_str = uio.StringIO()
    sys.print_exception(e, err_str)
    err_str = err_str.getvalue()
    img = image.Image(size=(224,224))
    img.draw_string(0, 10, err_str, scale=1, color=(0xff,0x00,0x00))
    lcd.display(img)

def main(labels = None, model_addr="/sd/m.kmodel", sensor_window=(224, 224), lcd_rotation=0, sensor_hmirror=False, sensor_vflip=False):
    sensor.reset()
    sensor.set_pixformat(sensor.RGB565)
    sensor.set_framesize(sensor.QVGA)
    sensor.set_windowing(sensor_window)
    sensor.set_hmirror(sensor_hmirror)
    sensor.set_vflip(sensor_vflip)
    sensor.run(1)

    lcd.init(type=1)
    lcd.rotation(lcd_rotation)
    lcd.clear(lcd.WHITE)

    if not labels:
        with open('labels.txt','r') as f:
            exec(f.read())
    if not labels:
        print("no labels.txt")
        img = image.Image(size=(320, 240))
        img.draw_string(90, 110, "no labels.txt", color=(255, 0, 0), scale=2)
        lcd.display(img)
        return 1
    try:
        img = image.Image("startup.jpg")
        lcd.display(img)
    except Exception:
        img = image.Image(size=(320, 240))
        img.draw_string(90, 110, "loading model...", color=(255, 255, 255), scale=2)
        lcd.display(img)

    task = kpu.load(model_addr)

    try:
        while(True):
            img = sensor.snapshot()
            t = time.ticks_ms()
            fmap = kpu.forward(task, img)
            t = time.ticks_ms() - t
            plist=fmap[:]
            pmax=max(plist) 
            max_index=plist.index(pmax)
            img.draw_string(0,0, "%.2f : %s" %(pmax, labels[max_index].strip()), scale=2)
            img.draw_string(0, 200, "t:%dms" %(t), scale=2)
            lcd.display(img)
    except Exception as e:
        raise e
    finally:
        kpu.deinit(task)


if __name__ == "__main__":
    try:
        labels = [] # labels
        # main(labels=labels, model_addr=0x300000)
        main(labels=labels, model_addr="/sd/m.kmodel")
    except Exception as e:
        sys.print_exception(e)
        lcd_show_except(e)
    finally:
        gc.collect()
