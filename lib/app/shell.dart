import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart' show PhoneFitScope;
import '../pages/home_page.dart';
import '../theme/tokens.dart';
import 'app_state.dart';
import 'routes.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/phone_frame.dart';

/// 应用外壳 —— 对应原型 index.html 的 `<div class="phone">` 容器，
/// 以及 app.js 里的 `render(id)` 调度。
///
/// 迁移策略：页面逐个替换。尚未迁移的页面走 [PlaceholderPage]，
/// 每个占位页都显示它在原型里的源文件行号，方便对照与排期。
class SurgoShell extends StatelessWidget {
  const SurgoShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final page = state.current;
    final hasNav = kNavPages.contains(page);
    final softBg = kSoftPages.contains(page);

    return PhoneFrame(
      // .phone.we-bg{background:#FCF8F5}：作答类页面整机换暖白
      background: softBg ? SurgoColors.warmWhite : null,
      backgroundImage: 'assets/images/app_bg.png',
      fitToScreen: PhoneFitScope.of(context),
      child: Stack(
        children: [
          // .screens{top:52px} —— 内容区从状态栏下沿开始
          Positioned.fill(
            top: SurgoDevice.statusBarHeight,
            bottom: 0,
            child: _PageViewport(page: page, hasNav: hasNav),
          ),

          // 状态栏与刘海压在最上层
          const Positioned(top: 0, left: 0, right: 0, child: PhoneStatusBar()),
          const Positioned(top: 0, left: 0, right: 0, child: PhoneNotch()),

          // 右上角全局按钮：个人中心页让位给消息通知；雅思模考作答页整体隐藏
          GlobalButtons(
            showSettings: page != SurgoPage.prep,
            showNotifications: true,
            onSettings: () => _openSettings(context),
            onNotifications: () => _openNotifications(context),
          ),

          if (hasNav)
            BottomNav(
              currentPage: page.name,
              onHome: () => state.go(SurgoPage.ielts),
              // navSel(el,'exam') → openMockSheet()：弹层而非跳页
              onExam: () => _openMockSheet(context),
              onReport: () => state.go(SurgoPage.report),
            ),
        ],
      ),
    );
  }

  void _openSettings(BuildContext context) {
    // TODO(迁移): 对应 toggleSetMenu() —— 首页设置弹窗
  }

  void _openNotifications(BuildContext context) {
    // TODO(迁移): 对应 toggleNoteMenu() —— 消息通知弹窗
  }

  void _openMockSheet(BuildContext context) {
    // TODO(迁移): 对应 openMockSheet() —— 考试选择底部抽屉
  }
}

/// 内容视口 —— 对应 `.screens` / `.screen` 两层。
///
/// 原型 `render()` 的入场动效：
///   `.screen{opacity:0;transform:translateY(14px) scale(.985)}`
///   → `.screen.active{opacity:1;transform:none}`，260ms 淡出 / 300ms 弹入。
class _PageViewport extends StatelessWidget {
  const _PageViewport({required this.page, required this.hasNav});

  final SurgoPage page;
  final bool hasNav;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: const Cubic(0.22, 1, 0.36, 1),
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _ScreenSurface(key: ValueKey(page), page: page, hasNav: hasNav),
    );
  }
}

class _ScreenSurface extends StatelessWidget {
  const _ScreenSurface({super.key, required this.page, required this.hasNav});

  final SurgoPage page;
  final bool hasNav;

  @override
  Widget build(BuildContext context) {
    // .screen{padding:8px 18px 30px}；.screen.has-nav{padding-bottom:120px}
    // .screen.flush{padding:8px 0 0}（首页用 flush）
    final flush = page == SurgoPage.ielts;
    return Padding(
      padding: EdgeInsets.only(
        left: flush ? 0 : SurgoDevice.screenPadH,
        right: flush ? 0 : SurgoDevice.screenPadH,
        top: SurgoDevice.screenPadTop,
        bottom: hasNav && page != SurgoPage.ielts
            ? SurgoDevice.screenPadBottomWithNav
            : SurgoDevice.screenPadBottom,
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final state = context.read<AppState>();
    switch (page) {
      case SurgoPage.ielts:
        return Padding(
          // 首页 flush 掉了左右内边距，这里补回来（原型 .home 自带 padding）
          padding: const EdgeInsets.symmetric(horizontal: SurgoDevice.screenPadH),
          child: HomePage(
            onOpenModule: () => _todo('openModuleModal(writing)'),
            onContinue: () => _todo('openContinueSheet()'),
            onReading: () => state.go(SurgoPage.readingDaily),
            onListening: () => state.go(SurgoPage.listeningDaily),
            onWriting: () => state.go(SurgoPage.writingDaily),
            onSpeaking: () => state.go(SurgoPage.speakingDaily),
            onVocab: () => state.go(SurgoPage.vocab),
            onPrep: () => state.go(SurgoPage.prep),
            onTrain: (p, v) => _todo('trainGo($p, $v)'),
            onLogo: () => state.go(SurgoPage.exam),
          ),
        );
      default:
        return PlaceholderPage(page: page);
    }
  }

  void _todo(String what) {
    debugPrint('[SURGO 迁移] 待实现：$what');
  }
}

/// 未迁移页面的占位 —— 明确标出源文件位置，避免"看起来像漏了"。
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.page});

  final SurgoPage page;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SurgoColors.card,
        borderRadius: SurgoRadius.baseAll,
        border: Border.all(color: SurgoColors.line),
        boxShadow: SurgoShadow.base,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('待迁移页面',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: SurgoColors.muted,
              )),
          const SizedBox(height: 6),
          Text(page.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: SurgoColors.ink,
              )),
          const SizedBox(height: 10),
          Text(
            '原型 app.js 的 V.${page.name}；'
            '模板原文见 _extract/pages/${page.name}.js',
            style: const TextStyle(
              fontSize: 13,
              height: 1.55,
              color: SurgoColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}