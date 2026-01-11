# Android Adaptive Icon - Image Placement Guide

## Required Files

After generating your foreground icon images, place them in these folders:

| Density | Size | Path |
|---------|------|------|
| mdpi | 108x108 | `android/app/src/main/res/mipmap-mdpi/ic_launcher_foreground.png` |
| hdpi | 162x162 | `android/app/src/main/res/mipmap-hdpi/ic_launcher_foreground.png` |
| xhdpi | 216x216 | `android/app/src/main/res/mipmap-xhdpi/ic_launcher_foreground.png` |
| xxhdpi | 324x324 | `android/app/src/main/res/mipmap-xxhdpi/ic_launcher_foreground.png` |
| xxxhdpi | 432x432 | `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png` |

## Quick Steps

1. Generate your icon at 432x432 pixels (xxxhdpi)
2. Resize to all 5 sizes listed above
3. Place files in corresponding mipmap folders
4. Run `flutter build appbundle --release` to verify

## Configuration Already Done ✅

- `mipmap-anydpi-v26/ic_launcher.xml` - adaptive icon config
- `mipmap-anydpi-v26/ic_launcher_round.xml` - round variant config
- `values/colors.xml` - white background color (#FFFFFF)

## Safe Zone

Your icon content should fit within the center 72dp circle (66% of total size).
The outer ring may be cropped on different device shapes.
