#!/bin/bash
# 无 Xcode 构建：只用 Command Line Tools 的 swiftc 产出可运行的 FocusFlow.app。
# 有 Xcode 时直接打开 FocusFlow.xcodeproj 即可，本脚本用于 CLT-only 环境和 CI。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/FocusFlow.app"
ARCH="$(uname -m)"
SDK="$(xcrun --sdk macosx --show-sdk-path)"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

# ---- CLT 16.x 已知 bug 规避：usr/include 重复定义 SwiftBridging 模块 ----
# 现象：任何 swiftc 编译报 "redefinition of module 'SwiftBridging'"
#（冷模块缓存下先极慢地反复解析 SDK 头文件，最后才报错，看起来像卡死）。
# 治本：升级 CLT（softwareupdate -i "Command Line Tools for Xcode 26.6-26.6"），
#       升级后本规避自动失效（检测不到冲突就不注入 flag）。
# 治标：VFS overlay 把两个冲突 modulemap 虚拟置空，不改动任何系统文件。
EXTRA_FLAGS=()
CLT_INC="/Library/Developer/CommandLineTools/usr/include"
CLT_MAJOR="$(pkgutil --pkg-info=com.apple.pkg.CLTools_Executables 2>/dev/null | sed -n 's/^version: \([0-9]*\).*/\1/p')"
# CLT 26+ 虽仍带重复文件但编译器不再误加载，只有 16/17 代 CLT 需要规避
if [ -n "$CLT_MAJOR" ] && [ "$CLT_MAJOR" -lt 26 ] \
   && grep -qs "module SwiftBridging" "$CLT_INC/swift/module.modulemap" \
   && grep -qs "module SwiftBridging" "$CLT_INC/module.modulemap"; then
    OVERLAY="$ROOT/build/clt-swiftbridging-fix.yaml"
    EMPTY="$ROOT/build/empty.modulemap"
    printf '// intentionally empty\n' > "$EMPTY"
    cat > "$OVERLAY" <<EOF
{ "version": 0, "use-external-names": false, "roots": [
  { "type": "file", "name": "$CLT_INC/swift/module.modulemap", "external-contents": "$EMPTY" },
  { "type": "file", "name": "$CLT_INC/swift/bridging.modulemap", "external-contents": "$EMPTY" }
] }
EOF
    EXTRA_FLAGS+=(-Xfrontend -vfsoverlay -Xfrontend "$OVERLAY" -Xcc -ivfsoverlay -Xcc "$OVERLAY")
    echo "==> 检测到 CLT SwiftBridging modulemap 冲突，启用 VFS overlay 规避"
fi

# 项目内模块缓存：首次构建慢（~1分钟建缓存），之后秒级
MODCACHE="$ROOT/build/module-cache"
mkdir -p "$MODCACHE"

echo "==> 编译 Swift 源码 (${ARCH}, SDK: ${SDK})"
swiftc -O -parse-as-library -swift-version 5 \
    -target "${ARCH}-apple-macos14.0" \
    -sdk "$SDK" \
    -module-cache-path "$MODCACHE" \
    ${EXTRA_FLAGS[@]+"${EXTRA_FLAGS[@]}"} \
    $(find "$ROOT/FocusFlow" -name '*.swift') \
    -o "$APP/Contents/MacOS/FocusFlow"

echo "==> 拷贝图标 + 通知配图"
# 视觉资源由 Scripts/make-icon.sh 预生成并提交进仓库；缺失时自动补生成，保证 CI/新机器可构建。
if [ ! -f "$ROOT/Resources/AppIcon.icns" ] || [ ! -f "$ROOT/Resources/notif-focus.png" ]; then
    echo "    视觉资源缺失，现场生成"
    bash "$ROOT/Scripts/make-icon.sh"
fi
cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
cp "$ROOT/Resources/notif-focus.png" "$APP/Contents/Resources/notif-focus.png"
cp "$ROOT/Resources/notif-break.png" "$APP/Contents/Resources/notif-break.png"

echo "==> 生成 Info.plist"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>FocusFlow</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIdentifier</key>
	<string>com.focusflow.FocusFlow</string>
	<key>CFBundleName</key>
	<string>FocusFlow</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.1.3</string>
	<key>CFBundleVersion</key>
	<string>5</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSHighResolutionCapable</key>
	<true/>
</dict>
</plist>
PLIST

echo "==> Ad-hoc 签名（本机运行 + 系统通知需要）"
codesign --force --sign - "$APP"

echo "==> 完成: $APP"
echo "    运行: open \"$APP\""
