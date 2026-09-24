import 'package:flutter/material.dart';

/// SURGO 设计令牌 —— 逐条对应 index.html 内联样式里的 `:root` 变量。
///
/// 原 H5 定义：
/// ```
/// :root{
///   --bg:#f7f3ee; --bg2:#faf6f0; --ink:#1c1a17; --muted:#8a8378;
///   --yellow:#F5B301; --yellow-soft:#fbe6ad; --yellow-tint:#fdf3d6;
///   --card:#ffffff; --line:#ece6dc; --blue:#3b6fd4; --blue-soft:#dbe6fb;
///   --radius:22px; --shadow:0 10px 30px rgba(60,50,20,.08);
/// }
/// ```
/// 颜色一律按原值取，不做"看起来差不多"的近似 —— 还原度优先。
class SurgoColors {
  const SurgoColors._();

  // ---- :root 变量 ----
  static const bg = Color(0xFFF7F3EE);
  static const bg2 = Color(0xFFFAF6F0);
  static const ink = Color(0xFF1C1A17);
  static const muted = Color(0xFF8A8378);
  static const yellow = Color(0xFFF5B301);
  static const yellowSoft = Color(0xFFFBE6AD);
  static const yellowTint = Color(0xFFFDF3D6);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFECE6DC);
  static const blue = Color(0xFF3B6FD4);
  static const blueSoft = Color(0xFFDBE6FB);

  // ---- body 背景（手机框外的画布） ----
  static const canvas = Color(0xFFE9E3D9);

  // ---- 高频散落值 ----
  /// 手机框边框 / 刘海 / 底部导航条
  static const deviceBlack = Color(0xFF111111);

  /// 作答类页面暖白底：.phone.we-bg{background:#FCF8F5}
  static const warmWhite = Color(0xFFFCF8F5);

  /// 底部悬浮导航胶囊
  static const navBar = Color(0xFF000000);
  static const navItem = Color(0xFF1A1A1A);

  /// 深色按钮 .btn-dark
  static const dark = Color(0xFF141210);

  /// 黄色卡上的深棕文字（pf-card / ot-go）
  static const onYellowStrong = Color(0xFF3A2E00);
  static const onYellowSoft = Color(0xFF6A5600);

  /// 倒计时超时
  static const overrun = Color(0xFFD9503F);

  /// 退出登录
  static const danger = Color(0xFFE5484D);

  /// 星级徽章文字
  static const goldInk = Color(0xFFB98A00);
  static const goldInkSoft = Color(0xFF9A7A00);

  /// 弹窗遮罩 rgba(20,15,5,.45)
  static const mask = Color(0x730F0F05);

  /// 进度条轨道
  static const track = Color(0xFFF1EBE0);

  /// 抽屉把手
  static const grip = Color(0xFFE3E7EC);

  /// 箭头灰
  static const arrow = Color(0xFFC4BBAA);

  /// 成功绿
  static const ok = Color(0xFF4F9E3A);

  /// 提示卡（黄底说明）
  static const noteBg = Color(0xFFFDF6E3);
  static const noteInk = Color(0xFF6A5A2A);

  /// .ot-go 按钮底色（比 --yellow 浅一档：#fbd45f）
  static const yellowButton = Color(0xFFFBD45F);
}

/// 圆角 —— 对应 CSS 里出现的各档 border-radius。
class SurgoRadius {
  const SurgoRadius._();

  /// --radius:22px
  static const base = 22.0;
  static const cardLg = 18.0;
  static const cardMd = 16.0;
  static const cardSm = 15.0;
  static const btn = 14.0;
  static const chip = 12.0;
  static const chipSm = 10.0;
  static const pill = 20.0;
  static const full = 999.0;

  /// 手机框 44px，底部抽屉 26px
  static const phone = 44.0;
  static const sheetTop = 26.0;
  static const dialog = 24.0;

  static const phoneFrame = BorderRadius.all(Radius.circular(phone));
  static const baseAll = BorderRadius.all(Radius.circular(base));
  static const cardLgAll = BorderRadius.all(Radius.circular(cardLg));
  static const btnAll = BorderRadius.all(Radius.circular(btn));
  static const chipAll = BorderRadius.all(Radius.circular(chip));
  static const pillAll = BorderRadius.all(Radius.circular(pill));
  static const fullAll = BorderRadius.all(Radius.circular(full));
  static const sheetTopAll =
      BorderRadius.vertical(top: Radius.circular(sheetTop));
  static const dialogAll = BorderRadius.all(Radius.circular(dialog));
}

/// 阴影 —— 对应 CSS 各处 box-shadow。
class SurgoShadow {
  const SurgoShadow._();

  /// --shadow:0 10px 30px rgba(60,50,20,.08)
  static const base = [
    BoxShadow(color: Color(0x14643214), blurRadius: 30, offset: Offset(0, 10)),
  ];

  /// 小卡片 0 6px 18px rgba(60,50,20,.05)
  static const card = [
    BoxShadow(color: Color(0x0D3C3214), blurRadius: 18, offset: Offset(0, 6)),
  ];

  /// welcome 卡把阴影做重了：0 20px 50px rgba(60,50,20,.38)
  static const welcome = [
    BoxShadow(color: Color(0x613C3214), blurRadius: 50, offset: Offset(0, 20)),
  ];

  /// 黄色卡 0 12px 26px rgba(245,179,1,.28)
  static const yellowCard = [
    BoxShadow(color: Color(0x47F5B301), blurRadius: 26, offset: Offset(0, 12)),
  ];

  /// 头像 0 8px 22px rgba(0,0,0,.12)
  static const avatar = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 22, offset: Offset(0, 8)),
  ];

  /// 手机框本体 0 30px 80px rgba(0,0,0,.35)
  static const device = [
    BoxShadow(color: Color(0x59000000), blurRadius: 80, offset: Offset(0, 30)),
  ];
}

/// 设备尺寸 —— 原型的画布是固定 390x844，边框 12px、刘海 30px、状态栏 52px。
class SurgoDevice {
  const SurgoDevice._();

  /// .phone{width:390px;height:844px;border:12px solid #111}
  static const screenWidth = 390.0;
  static const screenHeight = 844.0;
  static const frameBorder = 12.0;
  static const outerWidth = screenWidth + frameBorder * 2;
  static const outerHeight = screenHeight + frameBorder * 2;

  /// .notch{width:150px;height:30px}
  static const notchWidth = 150.0;
  static const notchHeight = 30.0;

  /// .statusbar{height:52px}
  static const statusBarHeight = 52.0;

  /// .screen{padding:8px 18px 30px}
  static const screenPadH = 18.0;
  static const screenPadTop = 8.0;
  static const screenPadBottom = 30.0;

  /// .screen.has-nav{padding-bottom:120px}
  static const screenPadBottomWithNav = 120.0;

  /// .fabnav{left:20px;right:20px;bottom:24px;height:74px}
  static const navInset = 20.0;
  static const navBottom = 24.0;
  static const navHeight = 74.0;
}

/// 字号 —— 原生 CSS px，直接当 Flutter 的逻辑像素用（原型本就是 1x 设计）。
///
/// ⚠️ 关键：原型画完之后会跑一次 `shrinkFonts()`，把**屏幕上所有元素**的字号减 2px，
/// 并以 [SurgoText.floor] 为下限。所以 CSS 里写的 20px 实际渲染是 18px，
/// 17px→15px，11px→10px（触底）。这不是笔误，是这套原型刻意的缩放，
/// 必须照搬，否则整站的文字都会偏大两号。
///
/// 换算：CSS 声明值 → 屏幕实际值 = `max(floor, 声明值 - shrink)`
class SurgoText {
  const SurgoText._();

  /// 全站字号下限，任何新文案不得低于此值（`const MIN_FONT=10`）
  static const floor = 10.0;

  /// shrinkFonts 的固定减量（`Math.max(MIN_FONT, fs-2)`）
  static const shrink = 2.0;

  /// 把 CSS 里写的字号换算成屏幕上实际的字号。
  ///
  /// [SurgoText.h1] 这类下面已经预换算好的常量优先用；
  /// 只有临时算不出常量时才调这个函数。
  static double css(double declared) =>
      (declared - shrink) < floor ? floor : declared - shrink;

  /// .h1{font-size:26px} → 屏幕 24px
  static const h1 = TextStyle(
    fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: SurgoColors.ink,
  );

  /// .sub{font-size:16px;line-height:1.5} → 14px
  static const sub = TextStyle(
    fontSize: 14,
    height: 1.5,
    color: SurgoColors.muted,
  );

  /// .sec-title{font-size:19px;font-weight:800} → 17px
  static const secTitle = TextStyle(
    fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: SurgoColors.ink,
  );

  /// .sec-sub{font-size:13px} → 11px
  static const secSub = TextStyle(fontSize: 11, color: SurgoColors.muted);

  /// .card .title{font-size:20px;font-weight:800} → 18px
  static const cardTitle = TextStyle(
    fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: SurgoColors.ink,
  );

  /// .card .en{font-size:13px;font-weight:600}（黄色）→ 11px
  static const cardEn = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: SurgoColors.yellow,
  );

  /// .card .desc{font-size:13px;line-height:1.55} → 11px
  static const cardDesc = TextStyle(
    fontSize: 11,
    height: 1.55,
    color: SurgoColors.muted,
  );

  /// .nav{font-size:15px} → 13px
  static const nav = TextStyle(fontSize: 13, color: SurgoColors.ink);

  /// .nav .back{font-weight:600} → 13px
  static const navBack = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: SurgoColors.ink,
  );

  /// .nav .brand{font-size:17px;font-weight:700} → 15px
  static const navBrand = TextStyle(
    fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: SurgoColors.ink,
  );

  /// .nav .nav-timer .cd-num{font-size:32px;font-weight:800;letter-spacing:.5px} → 30px
  static const countdownNumber = TextStyle(
    fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
    color: SurgoColors.ink,
  );

  /// .nav .nav-timer .cd-lbl{font-size:14px;font-weight:600}（灰色）→ 12px
  static const countdownLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: SurgoColors.muted,
  );

  /// .btn{font-weight:700;font-size:15px} → 13px
  static const button = TextStyle(
    fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: SurgoColors.ink,
  );

  /// .btn-block 文字居中 → 13px
  static const buttonBlock = TextStyle(
    fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: SurgoColors.ink,
    height: 1.0,
  );

  /// .sheet .q{font-size:23px;font-weight:800;line-height:1.25;letter-spacing:-.4px} → 21px
  static const sheetTitle = TextStyle(
    fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
    fontSize: 21,
    fontWeight: FontWeight.w800,
    height: 1.25,
    letterSpacing: -0.4,
    color: SurgoColors.deviceBlack,
  );

  /// .pf-name{font-size:22px;font-weight:800} → 20px
  static const profileName = TextStyle(
    fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: SurgoColors.ink,
  );

  /// .pf-top .pf-ttl{font-size:19px;font-weight:800} → 17px
  static const profileTitle = TextStyle(
    fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: SurgoColors.ink,
  );

  /// .pf-sec{font-size:14px;font-weight:700} → 12px
  static const profileSection = TextStyle(
    fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: SurgoColors.muted,
  );

  /// .lang{font-size:13px} → 11px
  static const language = TextStyle(fontSize: 11, color: SurgoColors.muted);

  /// .pf-row .pf-label{font-size:17px;font-weight:700} → 15px
  static const rowLabel = TextStyle(
    fontFamily: 'Outfit',fontFamilyFallback: SurgoFontFamily.fallback, 
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: SurgoColors.ink,
  );
}

/// 字体族。
///
/// 原 CSS：`font-family:'VioletSans',-apple-system,"PingFang SC","Helvetica Neue",Arial,sans-serif`
/// 用户 2026-09-24 指定：全局标题与副标题用 Outfit，题目与正文用 PingFang。
///
/// Outfit 只含拉丁字形，中文必须由 [fallback] 里的苹方接住；把苹方写进每一处
/// 回退链，而不是交给引擎自行挑选，否则 CanvasKit 会拿 notdef / 自动下载的字体
/// 凑数，中文就会出现杂散墨点。
///
/// 苹方与 SF Pro 同属 Apple，不可随包分发：这里只按族名引用，由 iOS / macOS
/// 系统解析，与源站 CSS 的写法一致，工程里不存放字体文件。
class SurgoFontFamily {
  const SurgoFontFamily._();

  /// 标题 / 副标题。
  static const heading = 'Outfit';

  /// 题目 / 正文 —— 系统苹方，未打包。
  static const body = 'PingFang SC';

  /// 默认继承族 = 正文。
  static const primary = body;

  /// 原型 @font-face 字体，仅个别沿用源站字形的位置使用。
  static const violetSans = 'VioletSans';

  /// 中文与拉丁回退链，对应源站 font-family 后半段。
  static const fallback = <String>[
    'PingFang SC',
    'Heiti SC',
    'Helvetica Neue',
    'Arial',
  ];
}
