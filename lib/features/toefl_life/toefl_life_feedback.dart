import '../../widgets/source_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/t.dart';
import 'toefl_life_logic.dart';

// 反馈页配色（index.html tffb-* / ra-*）—— 与 tfDwFb 反馈页同款调色板。
const _scoreBg = Color(0xFFFBE7A8); // .tffb-score background
const _scoreK = Color(0xFF7A6A30);
const _scoreD = Color(0xFF3A3520);
const _scoreF = Color(0xFF8A7C48);
const _weakBg = Color(0xFFFAF7F0); // .tffb-weak background
const _weakLine = Color(0xFFF0E8D6);
const _weakQInk = Color(0xFF3A352C);
const _noteInk = SurgoColors.muted;
const _yellowInk = Color(0xFF3A2E00);
const _tagPBg = Color(0xFFF3E8FF);
const _tagPInk = Color(0xFF7C3AED);
const _tagBBg = Color(0xFFE0F2FE);
const _tagBInk = Color(0xFF0369A1);
const _tagCBg = Color(0xFFDBEAFE);
const _tagCInk = Color(0xFF1D4ED8);
const _okBg = Color(0xFFE7F6EA); // .tffb-hit.ok / .tffb-tag.ok
const _okInk = Color(0xFF236B1F); // .tffb-hit.ok color
const _okTagInk = Color(0xFF2F7A2A);
const _badBg = Color(0xFFFDEAEA);
const _badInk = Color(0xFFA5301F);
const _badTagInk = Color(0xFFC0392B);
const _qnumOk = Color(0xFF2F9E44);
const _qnumBad = Color(0xFFC0392B);
const _ansOk = Color(0xFF2F7A2A);
const _ansBad = Color(0xFFC0392B);
const _expBg = Color(0xFFFDF9EE);
const _expLine = Color(0xFFF2E8CF);
const _expBInk = Color(0xFF3A352C);
const _expQInk = Color(0xFF6A6357);

/// 内容文字：原型数据是字符串，照旧走 [SourceText]；演示用真实数据
/// （tool/demo_export）给 `[英文, 中文]` 一对，交给 [T] 按界面语言取。
Widget _text(Object v, TextStyle style) =>
    v is List ? T(v, style: style) : SourceText('$v', style: style);

/// tfDlFb 反馈页。返回自然高度 Column（外层 shell 滚动）。
///
/// 对应 app.js 10075-10135 的 tfDlFbView：估分卡文案为原型内联硬编码
/// fixture（不发明任何真实评分），逐题/薄弱项/原文回看来自 toefl_life.json。
class TfDlFbView extends StatelessWidget {
  const TfDlFbView({super.key, required this.content, this.academic=false});
  final TfDlContent content;
  final bool academic;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // .ra-nav：home + 「练习回顾」tab（原型 onclick=go('ielts')）
        _RaNav(onHome: () => app.go(SurgoPage.ielts)),
        const SizedBox(height: 4),
        // .tffb-score —— 原型内联固定文案 fixture
        Container(
          decoration: BoxDecoration(
            color: _scoreBg,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // .tffb-score-k
              const T('\u603b\u4f53 \u00b7 \u7ec3\u4e60\u4f30\u5206',
                  style: TextStyle(fontSize: 13.5, color: _scoreK)),
              const SizedBox(height: 6),
              // .tffb-score-n：80.0 / 6.0（分数是内容 → Text）
              // 演示用真实数据带这一场的估分（content.score）；原型数据用原来写死的值。
              SourceText.rich(TextSpan(children: [
                TextSpan(
                  text: content.score ?? (academic?'60.0':'80.0'),
                  style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: SurgoColors.ink,
                    height: 1.1,
                  ),
                ),
                TextSpan(
                  text: ' / 6.0',
                  style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _scoreK,
                  ),
                ),
              ])),
              // .tffb-score-d \u2014\u2014 \u539f\u578b\u7684\u56fa\u5b9a\u8bc4\u8bed\uff1b\u540e\u7aef\u4e0d\u51fa\u6574\u573a\u8bc4\u8bed\uff0c\u771f\u5b9e\u6570\u636e\u4e0b\u4e0d\u753b\u8fd9\u4e00\u884c\u3002
              if (content.score == null) ...[
                const SizedBox(height: 10),
                const T(
                  '\u65e5\u5e38\u9605\u8bfb\u7a33\u5b9a\uff0c\u5b66\u672f\u6587\u7ae0\u662f\u4e3b\u8981\u63d0\u5347\u70b9\u3002',
                  style: TextStyle(fontSize: 13.5, height: 1.6, color: _scoreD),
                ),
              ],
              const SizedBox(height: 8),
              // .tffb-score-f
              const T(
                '\u7ec3\u4e60\u4f30\u5206\u4ec5\u4f9b\u53c2\u8003\uff0c\u4e0d\u4ee3\u8868\u5b98\u65b9\u6258\u798f\u5206\u6570\u3002',
                style: TextStyle(fontSize: 13, color: _scoreF),
              ),
            ],
          ),
        ),
        // 薄弱项分析卡
        _Card(
          children: [
            const T('\u8584\u5f31\u9879\u5206\u6790',
                style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: SurgoColors.ink)),
            const SizedBox(height: 6),
            const T(
              '\u4ec5\u57fa\u4e8e\u672c\u6b21\u4f5c\u7b54\u603b\u7ed3\uff0c\u5e76\u9644\u5e26\u5339\u914d\u7ec3\u4e60\u3002\u4ee5\u4f60\u7684\u754c\u9762\u8bed\u8a00\u663e\u793a\u3002',
              style:
                  TextStyle(fontSize: 13.5, height: 1.6, color: SurgoColors.muted),
            ),
            const SizedBox(height: 14),
            for (final w in content.weak) _WeakCard(w: w),
            const SizedBox(height: 12),
            const T(
              '\u4ec5\u8bb0\u5f55\u672c\u6b21\u80fd\u660e\u786e\u770b\u5230\u7684\u95ee\u9898\uff1b\u4e0d\u8bca\u65ad\u53e3\u97f3\u3001\u542c\u529b\u6216\u8bbe\u5907\u95ee\u9898\uff0c\u4e5f\u4e0d\u4e0b\u957f\u671f\u7ed3\u8bba\u3002',
              style: TextStyle(fontSize: 13, height: 1.6, color: _noteInk),
            ),
            const SizedBox(height: 14),
            // .tffb-btn：examType='toefl';go('readingDaily')
            _YellowBtn(
              label:
                  '\u7ec3\u4e60\u4f60\u6700\u5f31\u7684\u9898\u578b \u2192',
              onTap: () {
                app.examType = ExamType.toefl;
                app.go(SurgoPage.readingDaily);
              },
            ),
          ],
        ),
        // Passage 原文回看卡（.tffb-tcard）
        _TCard(rows: content.src, qs: content.qs),
        // 逐题分析卡
        _Card(
          children: [
            const T('\u9010\u9898\u5206\u6790',
                style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: SurgoColors.ink)),
            for (final q in content.qs) _QCard(q: q),
          ],
        ),
        const SizedBox(height: 4),
        // .ra-next：⌂ 回到首页（go('ielts')）
        _RaNext(onTap: () => app.go(SurgoPage.ielts)),
      ],
    );
  }
}

class _RaNav extends StatelessWidget {
  const _RaNav({required this.onHome});
  final VoidCallback onHome;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: onHome,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: SurgoColors.card,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14643214),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Center(
                child: SvgPicture.asset('assets/images/home_icon.svg',
                    width: 20, height: 20),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // .ra-tab.on：练习回顾（chrome → 过词典，大写由样式）
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const T(
                '\u7ec3\u4e60\u56de\u987e',
                uppercase: true,
                style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: SurgoColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Container(width: 48, height: 4, color: SurgoColors.yellow),
            ],
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SurgoColors.card,
        border: Border.all(color: SurgoColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _WeakCard extends StatelessWidget {
  const _WeakCard({required this.w});
  final TfDlWeak w;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _weakBg,
        border: Border.all(color: _weakLine),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3 个标签：p / b / c 三色（内容 → Text）
          Wrap(spacing: 8, runSpacing: 8, children: [
            _WTag(w.tags[0], _tagPBg, _tagPInk),
            _WTag(w.tags[1], _tagBBg, _tagBInk),
            _WTag(w.tags[2], _tagCBg, _tagCInk),
          ]),
          const SizedBox(height: 10),
          // .tffb-wq：斜体 + 左黄边
          Container(
            padding: const EdgeInsets.only(left: 10),
            decoration: const BoxDecoration(
              border:
                  Border(left: BorderSide(color: SurgoColors.yellow, width: 3)),
            ),
            child: _text(
              w.q,
              const TextStyle(
                fontSize: 13.5,
                fontStyle: FontStyle.italic,
                color: _weakQInk,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _text(w.a,
              const TextStyle(fontSize: 13.5, height: 1.65, color: _weakQInk)),
        ],
      ),
    );
  }
}

class _WTag extends StatelessWidget {
  const _WTag(this.text, this.bg, this.ink);
  final Object text;
  final Color bg;
  final Color ink;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: _text(text,
              TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontSize: 13, fontWeight: FontWeight.w700, color: ink)),
    );
  }
}

class _TCard extends StatelessWidget {
  const _TCard({required this.rows, required this.qs});
  final List<TfDlSrcRow> rows;
  final List<TfDlQ> qs;
  @override
  Widget build(BuildContext context) {
    // 逐片段拼成内联富文本：前文 + 命中(色块) + 题号(圆圈) + 后文。
    // 命中片段为空的行 → 纯文本（原型 !r[1] 分支只渲染 r[0]）。
    final spans = <InlineSpan>[];
    const base = TextStyle(fontSize: 13.5, height: 2, color: _weakQInk);
    for (final r in rows) {
      if (r.isPlain) {
        spans.add(TextSpan(text: r.before, style: base));
        continue;
      }
      // ok = TFDLFB_QS[r.qnum-1]?.ok ?? true（原型 q?q.ok:true）
      final ok =
          (r.qnum - 1 >= 0 && r.qnum - 1 < qs.length) ? qs[r.qnum - 1].ok : true;
      if (r.before.isNotEmpty) spans.add(TextSpan(text: r.before, style: base));
      // .tffb-hit 色块
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: ok ? _okBg : _badBg,
            borderRadius: BorderRadius.circular(5),
          ),
          child: SourceText(r.hit,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: ok ? _okInk : _badInk,
              )),
        ),
      ));
      // .tffb-qnum 圆圈
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: ok ? _qnumOk : _qnumBad,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: SourceText('${r.qnum}',
              style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              )),
        ),
      ));
      if (r.after.isNotEmpty) spans.add(TextSpan(text: r.after, style: base));
    }
    return Container(
      decoration: BoxDecoration(
        color: SurgoColors.card,
        border: Border.all(color: SurgoColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // .tffb-th：Passage（英文题面内容 → Text）
          const SourceText('Passage',
              style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: SurgoColors.ink)),
          const SizedBox(height: 10),
          SourceText.rich(TextSpan(children: spans)),
        ],
      ),
    );
  }
}

class _QCard extends StatelessWidget {
  const _QCard({required this.q});
  final TfDlQ q;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: SurgoColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 「第 N」含数字，chrome → 过词典
              // 词典只收了「第 1」到「第 7」，真实数据一页可以不止 7 题：直接给
              // [英文, 中文]（英文和词典的译法一致）。
              T(['Q${q.n}', '\u7b2c ${q.n}'],
                  style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: SurgoColors.ink)),
              const SizedBox(width: 10),
              // 表现良好/错误 标签
              Container(
                decoration: BoxDecoration(
                  color: q.ok ? _okBg : _badBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                child: T(
                  q.ok ? '\u8868\u73b0\u826f\u597d' : '\u9519\u8bef',
                  style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: q.ok ? _okTagInk : _badTagInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 「题目」标签 chrome
          const T('\u9898\u76ee',
              style: TextStyle(fontSize: 13, color: SurgoColors.muted)),
          const SizedBox(height: 4),
          // 题干内容 → Text
          SourceText(q.q,
              style: const TextStyle(
                  fontSize: 14, height: 1.55, color: SurgoColors.ink)),
          const SizedBox(height: 12),
          _AnsRow(
              label: '\u4f60\u7684\u4f5c\u7b54',
              value: q.mine,
              ink: q.ok ? _ansOk : _ansBad),
          if (q.ans != null) ...[
            const SizedBox(height: 7),
            _AnsRow(label: '\u6b63\u786e\u7b54\u6848', value: q.ans!, ink: _ansOk),
          ],
          if (q.why != null) _ExpBlock(why: q.why!, evi: q.evi ?? ''),
        ],
      ),
    );
  }
}

class _AnsRow extends StatelessWidget {
  const _AnsRow({required this.label, required this.value, required this.ink});
  final String label;
  final String value;
  final Color ink;
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // .tffb-ans-l 固定 58px，标签为 chrome
        SizedBox(
          width: 58,
          child: T(label,
              style: const TextStyle(fontSize: 13, color: SurgoColors.muted)),
        ),
        const SizedBox(width: 10),
        // 作答内容 → Text
        Expanded(
          child: SourceText(value,
              style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  color: ink)),
        ),
      ],
    );
  }
}

class _ExpBlock extends StatelessWidget {
  const _ExpBlock({required this.why, required this.evi});
  final Object why;
  final String evi;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 11),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _expBg,
        border: Border.all(color: _expLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 「解析」标签 chrome
          const T('\u89e3\u6790',
              style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: SurgoColors.ink)),
          const SizedBox(height: 7),
          // 解析正文内容 → Text
          _text(why,
              const TextStyle(fontSize: 13.5, height: 1.65, color: _expBInk)),
          const SizedBox(height: 9),
          // 「原文依据：」标签 chrome
          const T('\u539f\u6587\u4f9d\u636e\uff1a',
              style: TextStyle(fontSize: 13, color: SurgoColors.muted)),
          const SizedBox(height: 3),
          SourceText(evi,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                  color: _expQInk)),
        ],
      ),
    );
  }
}

class _YellowBtn extends StatelessWidget {
  const _YellowBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: SurgoColors.yellow,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Color(0x47F5B301), blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: T(label,
            style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                fontSize: 14, fontWeight: FontWeight.w800, color: _yellowInk)),
      ),
    );
  }
}

class _RaNext extends StatelessWidget {
  const _RaNext({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: SurgoColors.yellow,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x4DF5B301), blurRadius: 20, offset: Offset(0, 8)),
          ],
        ),
        padding: const EdgeInsets.all(17),
        // 「⌂ 回到首页」含符号，chrome → 过词典
        child: const T(
          '\u2302 \u56de\u5230\u9996\u9875',
          style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
              fontSize: 16, fontWeight: FontWeight.w800, color: _yellowInk),
        ),
      ),
    );
  }
}
