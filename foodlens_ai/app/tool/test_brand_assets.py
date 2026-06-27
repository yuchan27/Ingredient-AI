import hashlib
from pathlib import Path


EXPECTED_PNG_SIZES = {
    "assets/branding/app_icon.png": (1024, 1024),
    "assets/branding/app_icon_foreground.png": (1024, 1024),
    "assets/branding/app_icon_monochrome.png": (1024, 1024),
    "android/app/src/main/res/mipmap-mdpi/ic_launcher.png": (48, 48),
    "android/app/src/main/res/mipmap-hdpi/ic_launcher.png": (72, 72),
    "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png": (96, 96),
    "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png": (144, 144),
    "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png": (192, 192),
    "web/favicon.png": (16, 16),
    "web/icons/Icon-192.png": (192, 192),
    "web/icons/Icon-512.png": (512, 512),
    "web/icons/Icon-maskable-192.png": (192, 192),
    "web/icons/Icon-maskable-512.png": (512, 512),
}

FORBIDDEN_DEFAULT_HASHES = {
    "android/app/src/main/res/mipmap-mdpi/ic_launcher.png": (
        "c7c0c0189145e4e32a401c61c9bdc615754b0264e7afae24e834bb81049eaf81"
    ),
    "android/app/src/main/res/mipmap-hdpi/ic_launcher.png": (
        "6a7c8f0d703e3682108f9662f813302236240d3f8f638bb391e32bfb96055fef"
    ),
    "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png": (
        "e14aa40904929bf313fded22cf7e7ffcbf1d1aac4263b5ef1be8bfce650397aa"
    ),
    "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png": (
        "4d470bf22d5c17d84edc5f82516d1ba8a1c09559cd761cefb792f86d9f52b540"
    ),
    "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png": (
        "3c34e1f298d0c9ea3455d46db6b7759c8211a49e9ec6e44b635fc5c87dfb4180"
    ),
    "web/icons/Icon-192.png": (
        "3dce99077602f70421c1c6b2a240bc9b83d64d86681d45f2154143310c980be3"
    ),
    "web/icons/Icon-512.png": (
        "baccb205ae45f0b421be1657259b4943ac40c95094ab877f3bcbe12cd544dcbe"
    ),
    "windows/runner/resources/app_icon.ico": (
        "c098d3fc85cacff98b8e69811b48e9f0d852fcee278132d794411d978869cbf8"
    ),
}


def png_size(path: Path) -> tuple[int, int]:
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", path
    return tuple(
        int.from_bytes(data[offset : offset + 4], "big")
        for offset in (16, 20)
    )


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    for relative, expected in EXPECTED_PNG_SIZES.items():
        path = root / relative
        assert path.exists(), f"Missing {relative}"
        assert png_size(path) == expected, f"Wrong size for {relative}"

    for relative, forbidden in FORBIDDEN_DEFAULT_HASHES.items():
        digest = hashlib.sha256((root / relative).read_bytes()).hexdigest()
        assert digest != forbidden, f"Default icon remains: {relative}"

    ico = root / "windows/runner/resources/app_icon.ico"
    assert ico.read_bytes()[:4] == b"\x00\x00\x01\x00"
    print("Brand asset verification passed.")


if __name__ == "__main__":
    main()
