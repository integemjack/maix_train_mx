image_path = ""
image_only = ""
# images_files = os.listdir(JPEGImages)
# image_files = [file for file in images_files if file.endswith('.jpg')]

# 从folder1获取所有.jpg文件
image_files_folder1 = set(file for file in os.listdir(JPEGImages) if file.endswith('.jpg'))

# 从folder2获取所有.jpg文件
image_files_folder2 = set(file.split(".")[0] + ".jpg" for file in os.listdir(Annotations) if file.endswith('.txt'))

# 找出仅存在于folder1中的.jpg文件
unique_image_files_folder1 = image_files_folder1.difference(image_files_folder2)

# 如果需要转换回列表
image_files = list(unique_image_files_folder1)

if len(image_files) == 0:
    image_files = list(image_files_folder1)
# print(image_files)


point = 0
index = 0
last_category = CATEGORIE
colors = [(random.randint(1, 255), random.randint(1, 255), random.randint(1, 255)) for c in CATEGORIES]
# print(colors)

points = [{
    "cat": CATEGORIES[0],
    "top": True,
    "topX": -1,
    "topY": -1,
    "bottomX": -1,
    "bottomY": -1,
    "color": colors[0]
}]

# 创建一个画布
canvas = Canvas(width=400, height=280)

# 本地图片的路径（这里需要替换为你的图片文件路径）
# image_path = 'path/to/your/image.jpg'

def darm(snapshot):
    global points, point
    # snapshot = camera.copy()  # 读取图片
    for i, p in enumerate(points):
        # print(p)
        if p['bottomX'] >= 0 and p['bottomY'] >= 0:
            # 创建一个和原图像同样大小的透明图像
            overlay = snapshot.copy()

            # 在透明图像上绘制矩形
            if point == i:
                cv2.rectangle(overlay, (p['topX'], p['topY']), (p['bottomX'], p['bottomY']), p['color'] + (255,), 4)
                alpha = 1  # 设置透明度
            else:
                cv2.rectangle(overlay, (p['topX'], p['topY']), (p['bottomX'], p['bottomY']), p['color'] + (100,), 4)
                alpha = 0.2  # 设置透明度

            # 使用alpha blending将透明图像和原图像混合在一起
            
            snapshot = cv2.addWeighted(overlay, alpha, snapshot, 1 - alpha, 0)
        else:
            snapshot = cv2.circle(snapshot, (p['topX'], p['topY']), 4, p['color'], 3)
    # print(snapshot)
    return snapshot

# 定义鼠标按下的处理函数
def on_mouse_down(x, y):
    global points, point
    # 在点击的位置画一个圆
    # with hold_canvas(canvas):
    # canvas.fill_circle(x, y, 10)
    if points[point]['top']:
        points[point]['top'] = False
        points[point]['topX'] = x
        points[point]['topY'] = y
        points[point]['top_x_widget'].value = points[point]['topX']
        points[point]['top_y_widget'].value = points[point]['topY']
        points[point]['bottomX'] = -1
        points[point]['bottomY'] = -1
        points[point]['bottom_x_widget'].value = points[point]['bottomX']
        points[point]['bottom_y_widget'].value = points[point]['bottomY']

    else:
        points[point]['top'] = True
        points[point]['bottomX'] = x
        points[point]['bottomY'] = y
        points[point]['bottom_x_widget'].value = points[point]['bottomX']
        points[point]['bottom_y_widget'].value = points[point]['bottomY']


# 将鼠标按下事件绑定到处理函数
# canvas.bind("<Button-1>", on_mouse_down)
canvas.on_mouse_down(on_mouse_down)

def updateImage():
    # 使用opencv-python读取图片
    img = darm(cv2.imread(image_path))
    
    # 获取图片的高度、宽度和通道数
    height, width, channels = img.shape
    
    # 将BGR颜色通道转换为RGB
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    
    # canvas = Canvas(width=width, height=height)
    # 将图像数据放置到画布上
    # with hold_canvas(canvas):
    canvas.width = width
    canvas.height = height
    canvas.put_image_data(img_rgb, x=0, y=0)

def getOneImage():
    global image_files, image_path, image_only, index
    image_only = image_files[index]
    # Open the image file
    image_path = os.path.join(JPEGImages, image_only)

def getAnnotations():
    global image_only
    global add_point, points, point, last_category

    xml = os.path.join(Annotations, image_only.split(".")[0] + ".xml")

    point = 0
    for index, p in enumerate(points):
        del points[index]
    new_children = []
    points_widget.children = tuple(new_children)
    
    if not os.path.exists(xml):
        p = add_ponit({
            "cat": last_category,
            "top": True,
            "topX": -1,
            "topY": -1,
            "bottomX": -1,
            "bottomY": -1,
            "color": colors[0]
        }, len(points))
        points.append(p)
        setDefalutChoose(p, 0)
        return
    tree = ET.parse(xml)
    root = tree.getroot()
    
    # Loop over each 'object' element in the XML file
    for index, obj in enumerate(root.iter('object')):
        p = add_ponit({
            "cat": CATEGORIES[0],
            "top": True,
            "topX": -1,
            "topY": -1,
            "bottomX": -1,
            "bottomY": -1,
            "color": colors[index]
        }, len(points))
        points.append(p)
        setDefalutChoose(p, index)
        # Get the bounding box coordinates
        bndbox = obj.find('bndbox')
        xmin = int(bndbox.find('xmin').text)
        ymin = int(bndbox.find('ymin').text)
        xmax = int(bndbox.find('xmax').text)
        ymax = int(bndbox.find('ymax').text)

        points[index]['topX'] = xmin * 1
        points[index]['topY'] = ymin * 1
        points[index]['top_x_widget'].value = xmin * 1
        points[index]['top_y_widget'].value = ymin * 1
        points[index]['bottomX'] = xmax * 1
        points[index]['bottomY'] = ymax * 1
        points[index]['bottom_x_widget'].value = xmax * 1
        points[index]['bottom_y_widget'].value = ymax * 1


points_widget = ipywidgets.VBox([])

def add_ponit(p, index):
    global last_category
    
    # create widgets
    category_widget = ipywidgets.Dropdown(options=CATEGORIES, description='category', value=p['cat'])
    
    # 事件处理函数
    def on_category_change(change):
        global last_category
        # 'change'是一个包含改变信息的字典，'new'关键字对应新的值
        last_category = change['new']
        # print(f"下拉菜单的新选择是: {last_category}")

    # 为下拉菜单添加事件处理函数，观察'value'属性的变化
    category_widget.observe(on_category_change, names='value')

    top_x_widget = ipywidgets.IntText(description='Top X:')
    top_y_widget = ipywidgets.IntText(description='Top Y:')
    bottom_x_widget = ipywidgets.IntText(description='Bottom X:')
    bottom_y_widget = ipywidgets.IntText(description='Bottom Y:')

    def update_top_x_widget(change):
        # global topX
        p['topX'] = change['new']
    top_x_widget.observe(update_top_x_widget, names='value')

    def update_top_y_widget(change):
        # global topY
        p['topY'] = change['new']
        updateImage()
    top_y_widget.observe(update_top_y_widget, names='value')

    def update_bottom_x_widget(change):
        # global bottomX
        p['bottomX'] = change['new']
    bottom_x_widget.observe(update_bottom_x_widget, names='value')

    def update_bottom_y_widget(change):
        # global bottomY
        p['bottomY'] = change['new']
        updateImage()
    bottom_y_widget.observe(update_bottom_y_widget, names='value')
    
    choose_button = ipywidgets.Button(description='Choose')

    
    del_button = ipywidgets.Button(description='Del')

    
    box_layout = widgets.Layout(border='3px solid rgb{}'.format(p['color'][::-1]), margin_bottom='10px', background_color='lightblue')
    point_widget = ipywidgets.VBox([
        ipywidgets.HBox([category_widget, choose_button, del_button]),
        ipywidgets.HBox([top_x_widget, top_y_widget,]),
        ipywidgets.HBox([bottom_x_widget, bottom_y_widget]),
    ], layout=box_layout)
    p['category_widget'] = category_widget
    p['top_x_widget'] = top_x_widget
    p['top_y_widget'] = top_y_widget
    p['bottom_x_widget'] = bottom_x_widget
    p['bottom_y_widget'] = bottom_y_widget
    p['choose_button'] = choose_button
    p['point_widget'] = point_widget
    
    def choose(button):
        global point
        point = index
        for xi, xp in enumerate(points):
            if point == xi:
                choose_button.style.button_color = '#4898F8'
            else:
                xp['choose_button'].style.button_color = None
        updateImage()
        
    choose_button.on_click(choose)
    
    def del_b(button):
        global point
        new_children = [child for child in points_widget.children if child != point_widget]
        points_widget.children = tuple(new_children)
        if len(points) - 1 == index:
            point = point - 1
        del points[index]

        points[point]['choose_button'].style.button_color = '#4898F8'
        updateImage()

    del_button.on_click(del_b)
    points_widget.children = (*points_widget.children, point_widget)
    return p

def setDefalutChoose(p, index):
    global points, point
    
    if point == index or len(points) == 1:
        p['choose_button'].style.button_color = '#4898F8'
    else:
        p['choose_button'].style.button_color = None

# Add this to create a button for saving images
save_button = ipywidgets.Button(description='Save Image')

# Add this to define a function that will be called when the button is clicked
def save_image(b):
    global points
    
    # 获取当前时间
    current_time = datetime.datetime.now().strftime("%Y%m%d")

    # 构建文件名
    filename = image_only.split('.')[0]

    img = darm(cv2.imread(image_path))
    
    # 获取图片的高度、宽度和通道数
    height, width, channels = img.shape
    
    # Save the bounding box coordinates and category to a text file
    with open(os.path.join(Annotations, filename + '.txt'), 'w') as txtfile:  # Change 'data.txt' to your desired filename
        # Write the data for this image
        for p in points:
            if p['topX'] >= 0 and p['topY'] >= 0 and p['bottomX'] >= 0 and p['bottomY'] >= 0:
                x1 = p['topX']
                y1 = p['topY']
                x2 = p['bottomX']
                y2 = p['bottomY']
                category = p['cat']
                w = x2 - x1
                h = y2 - y1
                y_center = y1 + h / 2
                x_center = x1 + w / 2
                txtfile.write(f"{category} {x_center / width} {y_center / height} {w / width} {h / height}\n")
                
    # with open(labels, 'w') as file:
    #     for category in CATEGORIES:
    #         file.write(category + '\n')
    
    print('Image saved.')

# Add this to make the button call the function when clicked
save_button.on_click(save_image)


pre_button = ipywidgets.Button(description='Pre Image')
def pre_image(b):
    global index, image_files
    index -= 1
    if index < 0:
        index = len(image_files) - 1
    getOneImage()
    getAnnotations()
    updateImage()
    
pre_button.on_click(pre_image)

next_button = ipywidgets.Button(description='Next Image')
def next_image(b):
    global index
    index += 1
    if index >= len(image_files):
        index = 0
    getOneImage()
    getAnnotations()
    updateImage()
    
next_button.on_click(next_image)

def add_point_new(button):
    
    global add_point, ponits, last_category, colors
    
    if len(points) >= len(colors):
        colors.append((random.randint(1, 255), random.randint(1, 255), random.randint(1, 255)))
    
    p = add_ponit({
    "cat": last_category,
    "top": True,
    "topX": -1,
    "topY": -1,
    "bottomX": -1,
    "bottomY": -1,
    "color": colors[len(points)]
}, len(points))
    points.append(p)
    updateImage()
    
    
    
add_point_button = ipywidgets.Button(description='Add New Point')
add_point_button.on_click(add_point_new)



data_collection_widget = ipywidgets.VBox([
    ipywidgets.HBox([pre_button, canvas,next_button  ]),
    
    add_point_button,
    points_widget,
    save_button,
    ipywidgets.HBox([pre_button,next_button  ]),
    
])

getOneImage()
getAnnotations()
updateImage()

display(data_collection_widget)
print("data_collection_widget created")