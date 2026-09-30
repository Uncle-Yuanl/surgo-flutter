#!/usr/bin/env bash
# Vercel 构建入口（vercel.json 的 buildCommand），本地也能跑。
#
# 1. 用固定版本的 Flutter 构建 web：PATH 上的 flutter 版本对得上就直接用，否则浅克隆一份。
# 2. 把引擎按需下载的兜底字体（中文、Latin、符号、emoji）从 Google 拷进站点自己的
#    build/web/fonts/：国内打不开 fonts.gstatic.com，中文和 emoji 会缺字。
#    web/flutter_bootstrap.js 把 fontFallbackBaseUrl 指到这里；文件清单取自当前 SDK，
#    换 SDK 版本不用改脚本。浏览器语言是繁体 / 日文 / 韩文时引擎会要另外几套字体，
#    这里没拷（演示对象是简体中文浏览器）。
set -euo pipefail

FLUTTER_VERSION=3.44.4
FONT_FAMILIES='roboto|notosans|notosanssc|notosanssymbols|notosanssymbols2|notosansmath|notocoloremoji'

if ! flutter --version 2>/dev/null | grep -q "Flutter $FLUTTER_VERSION "; then
  SDK="${FLUTTER_HOME:-$HOME/flutter-$FLUTTER_VERSION}"
  [ -x "$SDK/bin/flutter" ] || git clone --depth 1 -b "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$SDK"
  export PATH="$SDK/bin:$PATH"
fi
flutter --disable-analytics >/dev/null 2>&1 || true
flutter build web --release --no-web-resources-cdn

ENGINE="$(dirname "$(command -v flutter)")/cache/flutter_web_sdk/lib/_engine/engine"
grep -ohE "\b($FONT_FAMILIES)/v[0-9]+/[^' ]+\.(woff2|ttf)" \
    "$ENGINE/font_fallback_data.dart" "$ENGINE/canvaskit/fonts.dart" \
  | sort -u \
  | xargs -P 8 -I{} curl -fsSL --retry 3 --create-dirs -o "build/web/fonts/{}" "https://fonts.gstatic.com/s/{}"
echo "fallback fonts: $(find build/web/fonts -type f | wc -l) files, $(du -sh build/web/fonts | cut -f1)"
