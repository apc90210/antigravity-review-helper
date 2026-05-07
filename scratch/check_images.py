import os
from PIL import Image

paths = ['assets/buttons', 'assets/alerts']
for path in paths:
    if not os.path.exists(path):
        continue
    for f in os.listdir(path):
        if f.endswith('.png'):
            full_path = os.path.join(path, f)
            try:
                img = Image.open(full_path)
                print(f'{full_path}: {img.size[0]}x{img.size[1]}')
            except Exception as e:
                print(f'{full_path}: Error {e}')
