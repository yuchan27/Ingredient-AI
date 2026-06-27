from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


SIZE = 1024
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "branding"
GREEN = "#1F7658"
APRICOT = "#F3B562"
CREAM = "#FFF8E9"
DEEP_GREEN = "#174E3E"


def _sparkle(
    draw: ImageDraw.ImageDraw,
    center: tuple[int, int],
    outer: int,
    inner: int,
    fill: str,
) -> None:
    cx, cy = center
    points = [
        (cx, cy - outer),
        (cx + inner, cy - inner),
        (cx + outer, cy),
        (cx + inner, cy + inner),
        (cx, cy + outer),
        (cx - inner, cy + inner),
        (cx - outer, cy),
        (cx - inner, cy - inner),
    ]
    draw.polygon(points, fill=fill)


def _foreground(*, colorized: bool) -> Image.Image:
    image = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    main = CREAM if colorized else "#FFFFFF"
    inner = APRICOT if colorized else "#FFFFFF"
    ink = DEEP_GREEN if colorized else "#FFFFFF"

    draw.line((690, 690, 842, 842), fill=main, width=112)
    draw.ellipse((202, 180, 750, 728), fill=main)
    draw.ellipse((300, 278, 652, 630), fill=inner)
    if colorized:
        draw.ellipse((395, 420, 431, 456), fill=ink)
        draw.ellipse((535, 420, 571, 456), fill=ink)
        draw.arc((390, 418, 584, 566), 28, 152, fill=ink, width=26)
        draw.arc((236, 214, 684, 662), 206, 288, fill="#FFFFFF", width=22)
    _sparkle(draw, (778, 198), 72, 20, main)
    return image


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)

    foreground = _foreground(colorized=True)
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.ellipse((210, 200, 770, 760), fill=(13, 62, 46, 90))
    shadow = shadow.filter(ImageFilter.GaussianBlur(28))

    master = Image.new("RGBA", (SIZE, SIZE), GREEN)
    master.alpha_composite(shadow)
    master.alpha_composite(foreground)
    master.save(OUT / "app_icon.png", optimize=True)
    foreground.save(OUT / "app_icon_foreground.png", optimize=True)
    _foreground(colorized=False).save(
        OUT / "app_icon_monochrome.png",
        optimize=True,
    )


if __name__ == "__main__":
    main()
