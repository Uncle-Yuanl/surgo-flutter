import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../app/routes.dart';
import '../theme/tokens.dart';
import 't.dart';

/// Shared native UI primitives. Sizes are CSS declarations after source shrinkFonts.
class SurgoTopBar extends StatelessWidget {
  const SurgoTopBar(
      {super.key,
      this.back = SurgoPage.ielts,
      this.label = '',
      this.onBack,
      this.title = '',
      this.center});
  final SurgoPage back;
  final String label, title;
  final VoidCallback? onBack;

  /// 顶栏中间位置的自定义内容，传入时**取代 logo**
  /// （用户 2026-09-24：考试页用计时代替上面的 logo）。
  final Widget? center;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 6, 2, 16),
        child: SizedBox(
            // 计时胶囊比 logo 高，让顶栏随内容长高；无 center 时仍是原来的 24。
            height: center == null ? 24 : 36,
            child: Stack(
                // 只有放计时胶囊时才垂直居中；无 center 时保持原来的顶部对齐，
                // 避免挪动全站 logo 的位置。
                alignment:
                    center == null ? Alignment.topCenter : Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                          onTap:
                              onBack ?? () => context.read<AppState>().go(back),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            SvgPicture.asset('assets/images/home_icon.svg',
                                width: 24, height: 24),
                          ]))),
                  if (center != null)
                    center!
                  else
                    IgnorePointer(
                        child: title.isNotEmpty
                            ? T(title, style: SurgoText.navBrand)
                            : Image.asset('assets/images/surgo_logo.png',
                                height: 28)),
                ])),
      );
}

class SurgoCard extends StatelessWidget {
  const SurgoCard(
      {super.key,
      required this.child,
      this.onTap,
      this.padding = const EdgeInsets.all(20),
      this.color = SurgoColors.card});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
          color: color,
          borderRadius: SurgoRadius.baseAll,
          textStyle: DefaultTextStyle.of(context).style,
          child: InkWell(
              onTap: onTap,
              borderRadius: SurgoRadius.baseAll,
              child: Container(
                  padding: padding,
                  decoration: BoxDecoration(
                      borderRadius: SurgoRadius.baseAll,
                      border: Border.all(color: SurgoColors.line)),
                  child: child))));
}

class SurgoButton extends StatelessWidget {
  const SurgoButton(this.label,
      {super.key, required this.onTap, this.primary = true, this.dark = false});
  final String label;
  final VoidCallback? onTap;
  final bool primary, dark;
  @override
  Widget build(BuildContext context) => Material(
      color: dark
          ? SurgoColors.dark
          : primary
              ? SurgoColors.yellow
              : Colors.white,
      textStyle: DefaultTextStyle.of(context).style,
      borderRadius: SurgoRadius.btnAll,
      child: InkWell(
          onTap: onTap,
          borderRadius: SurgoRadius.btnAll,
          child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                  borderRadius: SurgoRadius.btnAll,
                  border: primary || dark
                      ? null
                      : Border.all(color: SurgoColors.line)),
              child: Opacity(
                  opacity: onTap == null ? .4 : 1,
                  child: T(label,
                      textAlign: TextAlign.center,
                      style: SurgoText.button.copyWith(
                          color: dark ? Colors.white : SurgoColors.ink))))));
}

class SurgoHeading extends StatelessWidget {
  const SurgoHeading(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        T(title, style: SurgoText.h1),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          T(subtitle!, style: SurgoText.sub)
        ]
      ]));
}

Future<void> surgoPrototypeAlert(BuildContext context, String text) =>
    showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(content: T(text), actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context), child: const T('OK'))
            ]));
