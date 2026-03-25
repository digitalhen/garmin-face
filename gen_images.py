from PIL import Image, ImageDraw, ImageFont
import math, random

def draw_watch_face(draw, cx, cy, radius, bb_current, bb_day_high, square_size):
    """Draw the burndown watch face into the given draw context."""
    gap = 2
    used = 100 - bb_current

    # Collect visible squares
    visible = []
    diameter = radius * 2
    cols = (diameter + square_size - 1) // square_size
    rows = (diameter + square_size - 1) // square_size
    ox = cx - (cols * square_size) // 2
    oy = cy - (rows * square_size) // 2

    for row in range(rows):
        for col in range(cols):
            x = ox + col * square_size
            y = oy + row * square_size
            mx = x + square_size // 2
            my = y + square_size // 2
            dx = mx - cx
            dy = my - cy
            if dx * dx + dy * dy <= radius * radius:
                visible.append((x, y))

    green_count = int(bb_current * len(visible) / bb_day_high) if bb_day_high > 0 else 0
    red_count = len(visible) - green_count

    for i, (x, y) in enumerate(visible):
        if i < red_count:
            color = (180, 0, 0)
        else:
            color = (0, 120, 0)
        draw.rectangle([x, y, x + square_size - gap - 1, y + square_size - gap - 1], fill=color)


    # Draw text
    date_str = "Tue Mar 25"
    time_str = "14:30"
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", size=int(radius * 0.22))
    except:
        font = ImageFont.load_default()

    # Outline
    date_y = cy - int(radius * 0.12)
    time_y = cy + int(radius * 0.12)
    for dox in range(-2, 3):
        for doy in range(-2, 3):
            if dox != 0 or doy != 0:
                draw.text((cx + dox, date_y + doy), date_str, fill=(0, 0, 0), font=font, anchor="mm")
                draw.text((cx + dox, time_y + doy), time_str, fill=(0, 0, 0), font=font, anchor="mm")

    draw.text((cx, date_y), date_str, fill=(255, 255, 255), font=font, anchor="mm")
    draw.text((cx, time_y), time_str, fill=(255, 255, 255), font=font, anchor="mm")


# --- Hero Image: 1440x720 ---
hero = Image.new("RGB", (1440, 720), (15, 15, 15))
hd = ImageDraw.Draw(hero)

# Watch face on the right
draw_watch_face(hd, 1060, 360, 300, bb_current=62, bb_day_high=85, square_size=40)

# App name on the left — gradient from red to green per letter
try:
    title_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", size=80)
    sub_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", size=30)
except:
    title_font = ImageFont.load_default()
    sub_font = ImageFont.load_default()

title = "Burndown"
x_pos = 100
for i, ch in enumerate(title):
    t = i / (len(title) - 1)
    r = int(200 * (1 - t))
    g = int(160 * t)
    hd.text((x_pos, 310), ch, fill=(r, g, 0), font=title_font, anchor="lm")
    bbox = hd.textbbox((x_pos, 310), ch, font=title_font, anchor="lm")
    x_pos = bbox[2] + 1

hd.text((100, 380), "Body Battery Watch Face", fill=(100, 100, 100), font=sub_font, anchor="lm")

hero.save("/Users/henry/Code/garmin-face/hero_1440x720.png")

# --- Cover Image: 500x500 ---
cover = Image.new("RGB", (500, 500), (0, 0, 0))
cd = ImageDraw.Draw(cover)
draw_watch_face(cd, 250, 250, 220, bb_current=62, bb_day_high=85, square_size=32)
cover.save("/Users/henry/Code/garmin-face/cover_500x500.png")

# --- Screen Image: 280x280 (typical watch screenshot) ---
screen = Image.new("RGB", (280, 280), (0, 0, 0))
sd = ImageDraw.Draw(screen)
draw_watch_face(sd, 140, 140, 138, bb_current=62, bb_day_high=85, square_size=22)
screen.save("/Users/henry/Code/garmin-face/screen_280x280.png")

print("Generated: hero_1440x720.png, cover_500x500.png, screen_280x280.png")
