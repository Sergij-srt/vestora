import math
import os
from PIL import Image, ImageDraw, ImageFont

def draw_vestora_icon(size, is_maskable=False):
    # Create image with RGBA
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Background
    bg_color = (15, 15, 17, 255) # #0F0F11 Obsidian Black
    if is_maskable:
        # Maskable fills entire canvas with background
        draw.rectangle([0, 0, size, size], fill=bg_color)
    else:
        # Rounded squircle for standalone icon
        corner = int(size * 0.22)
        draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=corner, fill=bg_color)
        # Subtle gold perimeter border
        draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=corner, outline=(212, 175, 55, 60), width=max(1, int(size * 0.015)))

    # Outer circle badge
    center_x = size / 2
    center_y = size / 2
    badge_radius = size * (0.34 if is_maskable else 0.38)

    # Gold radial gradient / glow simulation
    for r_offset in range(int(size * 0.04), 0, -1):
        alpha = int(25 * (1 - r_offset / (size * 0.04)))
        glow_r = badge_radius + r_offset
        draw.ellipse(
            [center_x - glow_r, center_y - glow_r, center_x + glow_r, center_y + glow_r],
            outline=(212, 175, 55, alpha),
            width=2
        )

    # Central dark circular medallion
    draw.ellipse(
        [center_x - badge_radius, center_y - badge_radius, center_x + badge_radius, center_y + badge_radius],
        fill=(24, 24, 27, 255), # #18181B
        outline=(212, 175, 55, 220), # Gold #D4AF37
        width=max(2, int(size * 0.02))
    )

    # Draw the iconic Gold Clothes Hanger
    # Scale relative to badge
    gold_fill = (212, 175, 55, 255) # Gold
    line_w = max(3, int(size * 0.035))

    # Hook at top
    hook_r = size * 0.055
    hook_cx = center_x
    hook_cy = center_y - size * 0.12
    draw.arc(
        [hook_cx - hook_r, hook_cy - hook_r, hook_cx + hook_r, hook_cy + hook_r],
        start=210,
        end=45,
        fill=gold_fill,
        width=line_w
    )

    # Small top stem
    draw.line(
        [hook_cx + hook_r * 0.7, hook_cy + hook_r * 0.7, center_x, center_y - size * 0.05],
        fill=gold_fill,
        width=line_w
    )

    # Hanger triangle
    top_p = (center_x, center_y - size * 0.05)
    left_p = (center_x - size * 0.22, center_y + size * 0.12)
    right_p = (center_x + size * 0.22, center_y + size * 0.12)

    # Rounded triangle corners with lines
    draw.line([top_p, left_p], fill=gold_fill, width=line_w)
    draw.line([top_p, right_p], fill=gold_fill, width=line_w)
    draw.line([left_p, right_p], fill=gold_fill, width=line_w)

    # Small accent dots on ends of horizontal bar
    dot_r = line_w * 0.6
    draw.ellipse([left_p[0] - dot_r, left_p[1] - dot_r, left_p[0] + dot_r, left_p[1] + dot_r], fill=gold_fill)
    draw.ellipse([right_p[0] - dot_r, right_p[1] - dot_r, right_p[0] + dot_r, right_p[1] + dot_r], fill=gold_fill)

    # If large size and not maskable, add subtle "VESTORA" luxury branding at bottom
    if size >= 512 and not is_maskable:
        try:
            # Simple letter representation or dots
            pass
        except:
            pass

    return img

def main():
    icons_dir = r"c:\Users\Admin\Documents\NewProject\mobile_app\web\icons"
    os.makedirs(icons_dir, exist_ok=True)

    # Generate icons
    sizes = [
        ("Icon-192.png", 192, False),
        ("Icon-512.png", 512, False),
        ("Icon-maskable-192.png", 192, True),
        ("Icon-maskable-512.png", 512, True),
    ]

    for name, sz, maskable in sizes:
        icon = draw_vestora_icon(sz, is_maskable=maskable)
        out_path = os.path.join(icons_dir, name)
        icon.save(out_path, "PNG")
        print(f"Generated: {out_path} ({sz}x{sz}, maskable={maskable})")

    # Favicon (32x32, 64x64) and apple-touch-icon (180x180)
    apple_icon = draw_vestora_icon(180, is_maskable=False)
    apple_icon_path = os.path.join(icons_dir, "apple-touch-icon.png")
    apple_icon.save(apple_icon_path, "PNG")
    print(f"Generated: {apple_icon_path}")

    favicon = draw_vestora_icon(64, is_maskable=False)
    favicon_path = r"c:\Users\Admin\Documents\NewProject\mobile_app\web\favicon.png"
    favicon.save(favicon_path, "PNG")
    print(f"Generated: {favicon_path}")

if __name__ == "__main__":
    main()
