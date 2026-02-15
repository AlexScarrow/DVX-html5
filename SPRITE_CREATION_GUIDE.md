# Creating Placeholder Sprite Images

Since this is a Defold project, you need actual PNG images for the sprites. Here's how to create simple placeholders:

## Option 1: Create Manually in an Image Editor

Create PNG images with the following specifications:

### Cell Debug Sprites (250x150 pixels)

1. **cell_open.png**
   - 250x150 transparent or light gray rectangle
   - No borders

2. **cell_right_wall.png**
   - 250x150 light gray rectangle
   - White 5px border on the right edge

3. **cell_down_wall.png**
   - 250x150 light gray rectangle
   - White 5px border on the bottom edge

4. **cell_right_down_wall.png**
   - 250x150 light gray rectangle
   - White 5px borders on right and bottom edges

5. **cell_void.png**
   - 250x150 solid black rectangle

### Tile Sprites (750x450 pixels)

1. **tile_corridor.png**
   - 750x450 gray rectangle (corridor theme)

2. **tile_canteen.png**
   - 750x450 blue-ish rectangle (canteen theme)

3. **tile_armoury.png**
   - 750x450 red-ish rectangle (armoury theme)

## Option 2: Use ImageMagick (Command Line)

If you have ImageMagick installed, run these commands:

```bash
# Create directories
mkdir -p assets/images

# Cell debug sprites
convert -size 250x150 xc:gray80 assets/images/cell_open.png
convert -size 250x150 xc:gray80 -stroke white -strokewidth 5 -draw "line 245,0 245,150" assets/images/cell_right_wall.png
convert -size 250x150 xc:gray80 -stroke white -strokewidth 5 -draw "line 0,145 250,145" assets/images/cell_down_wall.png
convert -size 250x150 xc:gray80 -stroke white -strokewidth 5 -draw "line 245,0 245,150 line 0,145 250,145" assets/images/cell_right_down_wall.png
convert -size 250x150 xc:black assets/images/cell_void.png

# Tile sprites
convert -size 750x450 xc:gray60 -pointsize 72 -draw "text 200,250 'CORRIDOR'" assets/images/tile_corridor.png
convert -size 750x450 xc:"rgb(100,150,200)" -pointsize 72 -draw "text 200,250 'CANTEEN'" assets/images/tile_canteen.png
convert -size 750x450 xc:"rgb(200,100,100)" -pointsize 72 -draw "text 200,250 'ARMOURY'" assets/images/tile_armoury.png
```

## Option 3: Use Python with PIL

Create a Python script to generate the images:

```python
from PIL import Image, ImageDraw

# Create directory
import os
os.makedirs('assets/images', exist_ok=True)

# Cell sprites
def create_cell_sprite(filename, right_wall=False, down_wall=False, is_void=False):
    img = Image.new('RGBA', (250, 150), 'black' if is_void else (200, 200, 200))
    draw = ImageDraw.Draw(img)

    if right_wall:
        draw.rectangle([245, 0, 250, 150], fill='white')
    if down_wall:
        draw.rectangle([0, 145, 250, 150], fill='white')

    img.save(f'assets/images/{filename}')

create_cell_sprite('cell_open.png')
create_cell_sprite('cell_right_wall.png', right_wall=True)
create_cell_sprite('cell_down_wall.png', down_wall=True)
create_cell_sprite('cell_right_down_wall.png', right_wall=True, down_wall=True)
create_cell_sprite('cell_void.png', is_void=True)

# Tile sprites
def create_tile_sprite(filename, color, text):
    img = Image.new('RGB', (750, 450), color)
    img.save(f'assets/images/{filename}')

create_tile_sprite('tile_corridor.png', (150, 150, 150), 'CORRIDOR')
create_tile_sprite('tile_canteen.png', (100, 150, 200), 'CANTEEN')
create_tile_sprite('tile_armoury.png', (200, 100, 100), 'ARMOURY')

print("Sprite placeholders created successfully!")
```

## File Structure

After creating the images, your directory should look like:

```
/assets/
├── cells.atlas
├── tiles.atlas
└── images/
    ├── cell_open.png
    ├── cell_right_wall.png
    ├── cell_down_wall.png
    ├── cell_right_down_wall.png
    ├── cell_void.png
    ├── tile_corridor.png
    ├── tile_canteen.png
    └── tile_armoury.png
```

## Testing in Defold

1. Open the project in Defold Editor
2. Navigate to `/assets/cells.atlas` and `/assets/tiles.atlas`
3. The editor should automatically detect the images
4. If not, right-click the atlas and select "Rebuild"

## Next Steps

Once you have placeholder sprites working, you can replace them with proper artwork:
- Professional tile artwork with detail and atmosphere
- Character sprites for derples and aliens
- UI elements
- Effects and animations
