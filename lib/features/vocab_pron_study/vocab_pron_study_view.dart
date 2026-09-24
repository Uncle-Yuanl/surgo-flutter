import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/source_text.dart';
import '../../widgets/t.dart';
import '../vocab_details/vocab_detail_top.dart';
import 'vocab_pron_study_module.dart';

const _muted = Color(0xffa99a82);
const _speaker =
    '<svg viewBox="0 0 24 24" fill="none" stroke="#e0a80f" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M11 5 6 9H3v6h3l5 4z"/><path d="M15.5 8.5a5 5 0 0 1 0 7M18.5 5.5a9 9 0 0 1 0 13"/></svg>';
const _mic =
    '<svg viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="3" width="6" height="11" rx="3"/><path d="M6 11a6 6 0 0 0 12 0M12 17v4"/></svg>';
const _stop =
    '<svg viewBox="0 0 24 24" fill="#fff" stroke="none"><rect x="7" y="7" width="10" height="10" rx="2"/></svg>';

class VocabPronStudyView extends StatelessWidget {
  const VocabPronStudyView({super.key, required this.data});
  final VocabPronStudyData data;
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final zh = app.lang == UiLang.zh;
    final judge = data.phase == VocabPronPhase.judge;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      VocabDetailTop(
          progress: data.progress,
          fraction: data.barPct,
          exitTarget: SurgoPage.vocabPron),
      Container(
          key: const ValueKey('vp-card'),
          padding: const EdgeInsets.fromLTRB(24, 44, 24, 52),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0f3c3214),
                    blurRadius: 22,
                    offset: Offset(0, 8))
              ]),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SvgPicture.string(_speaker,
                  key: const ValueKey('vp-spk'), width: 30, height: 30),
              const SizedBox(width: 14),
              Flexible(child:SourceText(data.word,
                  key: const ValueKey('vp-word'),
                  style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.5,
                      height: (zh ? 62 : 44) / 44))),
            ]),
            const SizedBox(height: 6),
            SourceText(data.ipa,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, height: 21 / 15, color: _muted)),
            const SizedBox(height: 22),
            if (data.example != null) ...[
              SourceText(data.example!,
                  key: const ValueKey('vp-example'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, height: 1.6, color: Color(0xff6a6357))),
              const SizedBox(height: 34),
            ],
            if (judge) ...[
              T('本次未获得自动评分，请诚实评价这次朗读',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: (zh ? 21 : 15) / 15)),
              const SizedBox(height: 8),
              T('自动发音评分暂不可用；你的选择只影响复习计划。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      height: (zh ? 16 : 11) / 11,
                      color: _muted)),
              const SizedBox(height: 26),
              Wrap(
                  key: const ValueKey('vp-judge-buttons'),
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _Judge(good: false, onTap: () => app.go(data.forward)),
                    _Judge(good: true, onTap: () => app.go(data.forward)),
                  ]),
            ] else ...[
              T(
                  data.phase == VocabPronPhase.recording
                      ? '正在录音…点击停止'
                      : '大声朗读这个单词',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: (zh ? 21 : 15) / 15)),
              const SizedBox(height: 24),
              Center(
                  child: _Mic(
                      recording: data.phase == VocabPronPhase.recording,
                      onTap: () => app.go(data.forward))),
            ],
            const SizedBox(height: 22),
            if (judge)
              GestureDetector(
                  key: const ValueKey('vp-retake'),
                  onTap: () => app.go(data.retake!),
                  child: T('重新录音',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          height: (zh ? 17 : 12) / 12,
                          color: _muted)))
            else
              T('无法录音？改用手动评价',
                  key: const ValueKey('vp-manual'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      height: (zh ? 17 : 12) / 12,
                      color: _muted)),
          ])),
    ]);
  }
}

class _Mic extends StatelessWidget {
  const _Mic({required this.recording, required this.onTap});
  final bool recording;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
        BoxShadow(
            color:
                recording ? const Color(0x66f0483e) : const Color(0x66f5b301),
            blurRadius: 26,
            offset: const Offset(0, 10))
      ]),
      child: Material(
          color: recording ? const Color(0xfff0483e) : SurgoColors.yellow,
          shape: const CircleBorder(),
          child: InkWell(
              key: ValueKey(recording ? 'vp-mic-rec' : 'vp-mic'),
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Center(
                  child: SvgPicture.string(recording ? _stop : _mic,
                      key: const ValueKey('vp-mic-icon'),
                      width: 36,
                      height: 36)))));
}

class _Judge extends StatelessWidget {
  const _Judge({required this.good, required this.onTap});
  final bool good;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = good ? '#4f8a1f' : '#e5533c';
    final path = good ? 'M5 12l4 4 10-10' : 'M6 6l12 12M18 6L6 18';
    return Material(
        color: Colors.white,
        textStyle: DefaultTextStyle.of(context).style,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: good ? const Color(0xffb6dc95) : const Color(0xfff0b3a8),
                width: 1.5)),
        child: InkWell(
            key: ValueKey(good ? 'vp-judge-good' : 'vp-judge-bad'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 31, vertical: 16),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  SvgPicture.string(
                      '<svg viewBox="0 0 24 24" fill="none" stroke="$color" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="$path"/></svg>',
                      width: 20,
                      height: 20),
                  const SizedBox(width: 8),
                  T(good ? '读对了' : '没读好',
                      style: TextStyle(
                          fontFamily: 'Arimo',
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w700,
                          color: good
                              ? const Color(0xff3a3630)
                              : const Color(0xffe5533c))),
                ]))));
  }
}
