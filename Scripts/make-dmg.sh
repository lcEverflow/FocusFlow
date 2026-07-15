#!/bin/bash
# 打包 DMG：先跑 build.sh 产出 FocusFlow.app，再用 hdiutil 封装成
# 带 /Applications 快捷方式的压缩 DMG，输出到 build/FocusFlow-<version>.dmg。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-1.0.0}"
APP="$ROOT/build/FocusFlow.app"
DMG="$ROOT/build/FocusFlow-$VERSION.dmg"

bash "$ROOT/Scripts/build.sh"

echo "==> 组装 DMG 内容"
STAGE="$(mktemp -d /tmp/focusflow-dmg.XXXXXX)"
trap 'rm -rf "$STAGE"' EXIT
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

echo "==> 生成 $DMG"
rm -f "$DMG"
hdiutil create -volname "FocusFlow" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null

echo "==> 校验"
hdiutil verify "$DMG" >/dev/null && echo "    hdiutil verify: OK"
du -h "$DMG"
echo "==> 完成: $DMG"
