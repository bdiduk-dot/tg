import os
from PIL import Image, ImageDraw, ImageFilter

def create_app_icon(filename, bg_color, plane_color, fold_color, is_gradient=False, grad_start=None, grad_end=None):
    # Standard iPhone App Icon Size (180x180 pixels)
    size = (180, 180)
    image = Image.new("RGBA", size)
    draw = ImageDraw.Draw(image)
    
    # 1. Draw Background
    if is_gradient and grad_start and grad_end:
        # Create vertical gradient background
        for y in range(size[1]):
            r = int(grad_start[0] + (grad_end[0] - grad_start[0]) * (y / size[1]))
            g = int(grad_start[1] + (grad_end[1] - grad_start[1]) * (y / size[1]))
            b = int(grad_start[2] + (grad_end[2] - grad_start[2]) * (y / size[1]))
            draw.line([(0, y), (size[0], y)], fill=(r, g, b, 255))
    else:
        draw.rounded_rectangle([(0, 0), (size[0], size[1])], radius=40, fill=bg_color)
        
    # 2. Geometric Minimalist Paper Plane Coordinates (Sleek and flat iOS style)
    # Scaled to fit perfectly in 180x180 icon with safe margins
    body_points = [
        (55, 95),    # Left back tip
        (135, 45),   # Nose (pointing top-right)
        (95, 125),   # Right back tip
        (90, 100),   # Bottom crease joint
        (55, 95)
    ]
    
    fold_points = [
        (90, 100),   # Crease joint
        (95, 125),   # Right back tip
        (105, 105)   # Fold point
    ]
    
    # Draw shadow under the plane for premium 3D look
    shadow_image = Image.new("RGBA", size)
    shadow_draw = ImageDraw.Draw(shadow_image)
    shadow_body = [(x + 2, y + 4) for (x, y) in body_points]
    shadow_draw.polygon(shadow_body, fill=(0, 0, 0, 40))
    shadow_image = shadow_image.filter(ImageFilter.GaussianBlur(3))
    image.alpha_composite(shadow_image)
    
    # Draw main paper plane body
    draw.polygon(body_points, fill=plane_color)
    # Draw the wing fold with slightly darker shade for depth
    draw.polygon(fold_points, fill=fold_color)
    
    # Save the finished icon
    os.makedirs("d:/MyWork/OwnWork/ipaTelega/Icons", exist_ok=True)
    image.save(f"d:/MyWork/OwnWork/ipaTelega/Icons/{filename}", "PNG")
    print(f"Generated icon: {filename}")

# Generate simple, flat and premium icons:
if __name__ == "__main__":
    # 1. Regress Default (Clean Slate Blue Background)
    create_app_icon(
        "regress_default.png",
        bg_color=(34, 139, 230, 255),
        plane_color=(255, 255, 255, 255),
        fold_color=(200, 225, 250, 255)
    )
    
    # 2. Dark Premium (Pitch Dark Black with neon blue accent)
    create_app_icon(
        "dark_premium.png",
        bg_color=(15, 15, 15, 255),
        plane_color=(0, 212, 255, 255),
        fold_color=(0, 140, 200, 255)
    )
    
    # 3. Neon Regress (Deep Space Gray Background with Cyberpunk Neon Cyan/Purple)
    create_app_icon(
        "neon_regress.png",
        bg_color=(30, 30, 35, 255),
        plane_color=(243, 0, 193, 255),
        fold_color=(0, 243, 222, 255)
    )
    
    # 4. Gold Gradient (Polished Dark Charcoal Background with Luxury Gold Gradient)
    create_app_icon(
        "gold_gradient.png",
        bg_color=(24, 24, 27, 255),
        plane_color=(255, 215, 0, 255),
        fold_color=(204, 153, 0, 255)
    )
