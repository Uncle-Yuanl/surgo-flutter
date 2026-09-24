import '../../widgets/source_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/i18n.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import '../../widgets/primitives.dart';
import '../../widgets/t.dart';
import 'reading_gen_overlay.dart';
import 'reading_wizard_controller.dart';
import 'reading_wizard_data.dart';

/// 阅读日常训练向导页（`readingDaily`）—— 对应原型 app.js：
///   - IELTS：`wizardView('reading')`（第 1774-1865 行，双卡 pick2 版式）
///   - TOEFL：`tfReadingWizard()`（第 1730-1772 行，独立 tfrw 版式）
///
/// examType 决定走哪套版式，与原型 `wizardView` 顶部的分流一致：
/// `if(key==='reading' && examType==='toefl') return tfReadingWizard();`
///
/// 「生成题目」按钮 → `genSession('reading')` → 生成动画（[ReadingGenOverlay]）
/// → `doGenSession('reading')`（[ReadingWizardController.commitAndGo]）。
class ReadingWizardPage extends StatefulWidget {
  const ReadingWizardPage({super.key});

  @override
  State<ReadingWizardPage> createState() => _ReadingWizardPageState();
}

class _ReadingWizardPageState extends State<ReadingWizardPage> {
  late final ReadingWizardController _ctrl;
  ReadingWizardData? _data;

  @override
  void initState() {
    super.initState();
    _ctrl = ReadingWizardController(context.read<AppState>());
    ReadingWizardData.load().then((d) {
      if (mounted) setState(() => _data = d);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// `genSession('reading')`：先播生成动画，再提交并跳转。
  Future<void> _genSession() async {
    await ReadingGenOverlay.run(context);
    if (!mounted) return;
    _ctrl.commitAndGo();
  }

  void _back() => context.read<AppState>().go(SurgoPage.ielts);

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child:
            Center(child: CircularProgressIndicator(color: SurgoColors.yellow)),
      );
    }
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => _ctrl.isToefl
          ? _ToeflBody(
              ctrl: _ctrl, data: data, onGen: _genSession, onBack: _back)
          : _IeltsBody(
              ctrl: _ctrl, data: data, onGen: _genSession, onBack: _back),
    );
  }
}

// ============================================================ 公共步骤条

/// `.steps`（18/19 CSS）—— IELTS 侧三步进度：done / cur / 未完成。
class _StepsBar extends StatelessWidget {
  const _StepsBar({required this.step3Label});
  final String step3Label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 26, 0, 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: _step('1', 'Step 1', '生成题目', _StepState.done)),
          Expanded(child: _step('2', 'Step 2', '开始训练', _StepState.cur)),
          Expanded(child: _step('3', 'Step 3', step3Label, _StepState.todo)),
        ],
      ),
    );
  }

  Widget _step(String dot, String t, String d, _StepState st) {
    final done = st == _StepState.done;
    // .dot：done=黄底白字；cur/未完成=暖灰底
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: done ? SurgoColors.yellow : const Color(0xFFEFE9DD),
            shape: BoxShape.circle,
            boxShadow: done
                ? const [
                    BoxShadow(
                        color: Color(0x4DF5B301),
                        blurRadius: 6,
                        offset: Offset(0, 2))
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: SourceText(dot,
              style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: done ? Colors.white : const Color(0xFFB3AA98))),
        ),
        const SizedBox(width: 8),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            T(t,
                style: const TextStyle(
                    fontSize: 11,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFB3AA98))),
            T(d,
                style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    // done=#3a2e00；cur/未完成=#c4bbaa
                    color: done
                        ? const Color(0xFF3A2E00)
                        : const Color(0xFFC4BBAA))),
          ],
        )),
      ],
    );
  }
}

enum _StepState { done, cur, todo }

/// `.field-label`
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.topGap = 24});
  final String text;
  final double topGap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(0, topGap, 0, 12),
        child: T(text,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: SurgoColors.muted)),
      );
}

/// `.inp` 话题输入框（选填）。
class _TopicInput extends StatelessWidget {
  const _TopicInput();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Color(0x143C321E), blurRadius: 18, offset: Offset(0, 4)),
          ]),
      child: TextField(
        style: const TextStyle(fontSize: 14, color: SurgoColors.ink),
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          hintText: Translator.instance.translate(
                  '留空的话，我们会为你选择一个话题', context.watch<AppState>().lang) ??
              '留空的话，我们会为你选择一个话题',
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFC2BBAE)),
        ),
      ),
    );
  }
}

/// `.row-btns`：主按钮 + 返回。
class _RowBtns extends StatelessWidget {
  const _RowBtns({required this.onGen, required this.onBack});
  final VoidCallback onGen, onBack;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Row(children: [
          Expanded(
              child: SurgoButton('生成题目',
                  key: const ValueKey('reading-generate'), onTap: onGen)),
          const SizedBox(width: 12),
          SizedBox(
              width: 72,
              child: SurgoButton('返回', onTap: onBack, primary: false)),
        ]),
      );
}

// ============================================================ IELTS 版式

class _IeltsBody extends StatelessWidget {
  const _IeltsBody(
      {required this.ctrl,
      required this.data,
      required this.onGen,
      required this.onBack});
  final ReadingWizardController ctrl;
  final ReadingWizardData data;
  final VoidCallback onGen, onBack;

  @override
  Widget build(BuildContext context) {
    final single = ctrl.readMode == 'single';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SurgoTopBar(label: '雅思首页', back: SurgoPage.ielts),
      SurgoCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: const EdgeInsets.only(top: 6),
              child: T('IELTS 阅读（日常训练）',
                  style: SurgoText.h1
                      .copyWith(fontSize: 22, height: kTextHeightNone))),
          const SizedBox(height: 4),
          const T('练习整篇文章，或针对性攻克那个总丢分的题型。', style: SurgoText.sub),
          const _StepsBar(step3Label: '批改与复盘'),
          const _FieldLabel('今天想怎么练？', topGap: 0),
          // .pick2：练习整篇 / 专注单一
          _PracticeCard(
            selected: !single,
            recommend: true,
            title: '练习整篇',
            sub: '随机 3 种题型，最接近真实考试。',
            icon: 'assets/images/pick_full.svg',
            onTap: () => ctrl.pickPracticeMode('full'),
          ),
          const SizedBox(height: 14),
          _PracticeCard(
            selected: single,
            recommend: false,
            title: '专注单一',
            sub: '针对性攻克一个薄弱题型。',
            icon: 'assets/images/pick_single.svg',
            onTap: () => ctrl.pickPracticeMode('single'),
            trailing: single
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _TypeSelect(
                      options: data.readingOptions,
                      value: ctrl.selReadType,
                      placeholder: '请选择想练习的题型',
                      onChanged: (v) => ctrl.pickReadType(v),
                    ),
                  )
                : null,
          ),
          // reading.topic=true
          const _FieldLabel('话题（选填）'),
          const _TopicInput(),
          _RowBtns(onGen: onGen, onBack: onBack),
        ]),
      ),
    ]);
  }
}

/// `.pcard`（20 CSS）—— 双卡的单张。未选中 opacity .5。
class _PracticeCard extends StatelessWidget {
  const _PracticeCard({
    required this.selected,
    required this.recommend,
    required this.title,
    required this.sub,
    required this.icon,
    required this.onTap,
    this.trailing,
  });
  final bool selected, recommend;
  final String title, sub, icon;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: selected ? 1 : .5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFFDF6) : const Color(0xFFF3F0EA),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? SurgoColors.yellow : SurgoColors.line,
                width: 2),
            boxShadow: selected
                ? const [
                    BoxShadow(
                        color: Color(0x17000000),
                        blurRadius: 26,
                        offset: Offset(0, 12))
                  ]
                : null,
          ),
          child: Stack(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                // .pic 72x72
                SvgPicture.asset(icon, width: 72, height: 72),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        T(title,
                            style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: SurgoColors.ink,
                                letterSpacing: -.2)),
                        const SizedBox(height: 6),
                        T(sub,
                            style: const TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: SurgoColors.muted)),
                      ]),
                ),
              ]),
              if (trailing != null) trailing!,
            ]),
            // .prec（推荐）/ .pcheck（选中勾）在右上角
            Positioned(
              top: 0,
              right: 0,
              child: recommend
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                          color: SurgoColors.yellow,
                          borderRadius: BorderRadius.circular(8)),
                      child: const T('推荐',
                          style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF3A2E00))),
                    )
                  : (selected
                      ? Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                              color: SurgoColors.yellow,
                              shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: const SourceText('✓',
                              style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        )
                      : const SizedBox.shrink()),
            ),
          ]),
        ),
      ),
    );
  }
}

/// `.sel-inp` 题型下拉（专注单一时出现）。
class _TypeSelect extends StatelessWidget {
  const _TypeSelect({
    required this.options,
    required this.value,
    required this.placeholder,
    required this.onChanged,
  });
  final List<({String value, String label})> options;
  final String? value;
  final String placeholder;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SurgoColors.line, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFA99A72)),
          hint: T(placeholder,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFC2BBAE))),
          items: [
            for (final o in options)
              DropdownMenuItem(
                value: o.value,
                // 题型名是"题目内容/枚举"，但这里是 chrome 选项，仍走 T 词典
                child: T(o.label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: SurgoColors.ink)),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ============================================================ TOEFL 版式

class _ToeflBody extends StatelessWidget {
  const _ToeflBody(
      {required this.ctrl,
      required this.data,
      required this.onGen,
      required this.onBack});
  final ReadingWizardController ctrl;
  final ReadingWizardData data;
  final VoidCallback onGen, onBack;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SurgoTopBar(label: '托福首页', back: SurgoPage.ielts),
      SurgoCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const T('TOEFL 阅读（日常训练）', style: SurgoText.h1),
          const SizedBox(height: 4),
          const T('单独练习一个托福阅读任务，我们会为你生成文章。完成后立即获得反馈，同一任务可反复练习。',
              style: SurgoText.sub),
          const _TfSteps(),
          const _FieldLabel('选择题型', topGap: 0),
          // .tfrw-grid
          for (int i = 0; i < data.tfReadTasks.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _TfTaskCard(
              task: data.tfReadTasks[i],
              iconAsset: data.tfIconAsset(data.tfReadTasks[i].key),
              selected: data.tfReadTasks[i].key == ctrl.tfReadTask,
              onTap: () => ctrl.pickTfReadTask(data.tfReadTasks[i].key),
            ),
          ],
          const _FieldLabel('难度'),
          _TfSeg(
            diffs: data.tfReadDiffs,
            value: ctrl.tfReadDiff,
            onPick: ctrl.pickTfReadDiff,
          ),
          const _FieldLabel('话题（选填）'),
          const _TopicInput(),
          _RowBtns(onGen: onGen, onBack: onBack),
        ]),
      ),
    ]);
  }
}

/// `.tfrw-steps`（23 CSS）—— 三个圆形图标步骤，第一步 on。
class _TfSteps extends StatelessWidget {
  const _TfSteps();
  @override
  Widget build(BuildContext context) {
    // 原型 steps：[生成题目 on][——on——][开始训练][——][回顾与批改]
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 22, 0, 26),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _st('生成题目', true),
        _line(true),
        _st('开始训练', false),
        _line(false),
        _st('回顾与批改', false),
      ]),
    );
  }

  Widget _st(String lbl, bool on) => SizedBox(
        width: 64,
        child: Column(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: on ? SurgoColors.yellowSoft : const Color(0xFFFDF3D6),
              shape: BoxShape.circle,
              boxShadow: on
                  ? const [
                      BoxShadow(
                          color: Color(0x21F5B301),
                          blurRadius: 0,
                          spreadRadius: 7)
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Icon(_ic(lbl),
                size: 22,
                color: on ? const Color(0xFF8A6A00) : const Color(0xFFE0A800)),
          ),
          const SizedBox(height: 9),
          T(lbl,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color:
                      on ? const Color(0xFF3A352C) : const Color(0xFFB3AA98))),
        ]),
      );

  IconData _ic(String lbl) {
    switch (lbl) {
      case '生成题目':
        return Icons.auto_awesome;
      case '开始训练':
        return Icons.fitness_center;
      default:
        return Icons.rate_review_outlined;
    }
  }

  Widget _line(bool on) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 21),
          child: Container(
            height: 3,
            decoration: BoxDecoration(
                color: on ? SurgoColors.yellowSoft : const Color(0xFFF2ECDC),
                borderRadius: BorderRadius.circular(3)),
          ),
        ),
      );
}

/// `.tfrw-card`（23/196/197 CSS）
class _TfTaskCard extends StatelessWidget {
  const _TfTaskCard(
      {required this.task,
      required this.iconAsset,
      required this.selected,
      required this.onTap});
  final TfReadTask task;
  final String? iconAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 44, 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFFDF6) : const Color(0xFFF7F5F0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? SurgoColors.yellow : SurgoColors.line,
              width: 2),
          boxShadow: selected
              ? const [
                  BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 24,
                      offset: Offset(0, 10))
                ]
              : null,
        ),
        child: Stack(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (iconAsset != null)
                SvgPicture.asset(iconAsset!, width: 42, height: 42),
              const SizedBox(width: 11),
              Flexible(
                child: T(task.title,
                    style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: SurgoColors.ink,
                        letterSpacing: -.2)),
              ),
            ]),
            const SizedBox(height: 9),
            T(task.sub,
                style: const TextStyle(
                    fontSize: 13.5, height: 1.5, color: SurgoColors.muted)),
            const SizedBox(height: 11),
            // .tfrw-tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                  color: selected
                      ? SurgoColors.yellowTint
                      : const Color(0x0F000000),
                  borderRadius: BorderRadius.circular(9)),
              child: T(task.tag,
                  style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? const Color(0xFF9A7A00)
                          : const Color(0xFF6A6459))),
            ),
          ]),
          // .tfrw-chk：选中才显示
          if (selected)
            Positioned(
              top: -3,
              right: -30,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                    color: SurgoColors.yellow, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const SourceText('✓',
                    style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ),
        ]),
      ),
    );
  }
}

/// `.tfrw-seg`（23 CSS）—— 难度分段选择。
class _TfSeg extends StatelessWidget {
  const _TfSeg(
      {required this.diffs, required this.value, required this.onPick});
  final List<TfReadDiff> diffs;
  final String value;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: const Color(0xFFF0EDE6),
            borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final d in diffs)
            GestureDetector(
              onTap: () => onPick(d.k),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                decoration: BoxDecoration(
                  color: d.k == value ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: d.k == value
                      ? const [
                          BoxShadow(
                              color: Color(0x17000000),
                              blurRadius: 6,
                              offset: Offset(0, 2))
                        ]
                      : null,
                ),
                child: T(d.label,
                    style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: d.k == value
                            ? SurgoColors.ink
                            : const Color(0xFFA09884))),
              ),
            ),
        ]),
      ),
    );
  }
}
