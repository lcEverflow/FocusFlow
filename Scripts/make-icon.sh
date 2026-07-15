#!/bin/bash
# 生成 App 图标：Swift 画 1024 母图 → sips 切各尺寸 iconset → iconutil 打 AppIcon.icns。
# 全程只用系统自带工具（swift / sips / iconutil），CLT 即可，无需 Xcode。
# 产物提交进仓库（Resources/），build.sh 直接引用，无需每次重生成。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RES="$ROOT/Resources"
MASTER="$RES/AppIcon-1024.png"
ICONSET="$ROOT/build/AppIcon.iconset"
ICNS="$RES/AppIcon.icns"

mkdir -p "$RES"

echo "==> 渲染 1024 母图"
swift "$ROOT/Scripts/make-icon.swift" "$MASTER"

echo "==> 生成 iconset 各尺寸"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
gen() { sips -z "$1" "$1" "$MASTER" --out "$ICONSET/$2" >/dev/null; }
gen 16   icon_16x16.png
gen 32   icon_16x16@2x.png
gen 32   icon_32x32.png
gen 64   icon_32x32@2x.png
gen 128  icon_128x128.png
gen 256  icon_128x128@2x.png
gen 256  icon_256x256.png
gen 512  icon_256x256@2x.png
gen 512  icon_512x512.png
cp "$MASTER" "$ICONSET/icon_512x512@2x.png"

echo "==> 打包 AppIcon.icns"
iconutil -c icns "$ICONSET" -o "$ICNS"

echo "==> 渲染通知配图"
swift "$ROOT/Scripts/make-notif-images.swift" "$RES"

echo "==> 完成: $ICNS + 通知配图"
du -h "$ICNS" "$RES"/notif-*.png
