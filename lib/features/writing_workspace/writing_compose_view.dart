import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../app/routes.dart';
import '../../app/i18n.dart';
import '../../theme/tokens.dart';
import '../../widgets/source_text.dart';
import '../../widgets/t.dart';
import '../../widgets/marking_dialog.dart';
import 'writing_controller.dart';
import 'writing_compose_widgets.dart';
import 'writing_plan_panel.dart';
import 'writing_source_chart.dart';

class WritingComposeView extends StatefulWidget {
  const WritingComposeView({super.key, required this.controller});
  final WritingController controller;
  @override
  State<WritingComposeView> createState() => _WritingComposeViewState();
}

class _WritingComposeViewState extends State<WritingComposeView> {
  WritingController get c => widget.controller;
  late final TextEditingController text;
  bool countChanged = false;
  bool get essay => c.tab == 'essay';
  // Verified online: render's if(id!='tfDailyInterview') branch skips the later
  // writingCompose else-if. The current source leaves00:00:00, cdTimer=null.
  String get clock => '00:00:00';
  @override
  void initState() {
    super.initState();
    text = TextEditingController(text: c.draft);
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  void route() {
    c.draft = text.text;
    c.state.go(SurgoPage.writingCompose);
  }

  void tab(String value) {
    c.tab = value;
    route();
  }

  void changed(String module) {
    if (module == 'arg') {
      route();
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, bounds) {
        final nav = ComposeNav(
            essay: essay, home: () => c.state.go(SurgoPage.ielts), tab: tab);
        final cta = ComposeCta(essay ? '提交批改' : 'Start Writing', onTap: () {
          c.draft = text.text;
          if (essay) {
            showMarking(
                context, SurgoPage.writingFeedback, '正在批改任务 1 / 2, Task 1');
          } else {
            tab('essay');
          }
        });
        final body = essay ? _editor() : _topics();
        if (!bounds.hasBoundedHeight) {
          return SizedBox(
              height: 784,
              child: Column(children: [nav, Expanded(child: body), cta]));
        }
        return Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [nav, Expanded(child: body), cta]));
      });
  Widget _topics() {
    final open = c.state.session['wePlanOpen'] == true,
        mod = c.state.session['wePlanMod'] as String? ?? '';
    final task = c.task;
    return SingleChildScrollView(
        key: const ValueKey('compose-scroll'),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: composeCardDecoration(),
              child: ComposeDisclosure(
                  key: const ValueKey('compose-fold'),
                  label: 'Composition planning',
                  open: open,
                  main: true,
                  onTap: () {
                    c.state.session['wePlanOpen'] = !open;
                    if (open) {
                      c.state.session['wePlanMod'] = '';
                    }
                    route();
                  })),
          if (open)
            for (var i = 0; i < 4; i++) ...[
              Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: composeCardDecoration(),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ComposeDisclosure(
                                key: ValueKey(
                                    'compose-module-${WritingController.steps[i]}'),
                                label: ['题目分析', '论点选择', '段落规划', '主题词汇'][i],
                                open: mod == WritingController.steps[i],
                                onTap: () {
                                  c.state.session['wePlanMod'] =
                                      mod == WritingController.steps[i]
                                          ? ''
                                          : WritingController.steps[i];
                                  route();
                                }),
                            if (mod == WritingController.steps[i])
                              Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: WritingPlanPanel(
                                      controller: c,
                                      step: mod,
                                      embedded: true,
                                      changed: () => changed(mod))),
                          ]))),
            ],
          Container(
              key: const ValueKey('compose-topic'),
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: composeCardDecoration(),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                                color: const Color(0xffe6e2fb),
                                borderRadius: BorderRadius.circular(11)),
                            child: const T('Essentials',
                                style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xff6b5fc7))))),
                    const SizedBox(height: 14),
                    T(task['title'] ?? '',
                        style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.3,
                            color: SurgoColors.ink)),
                    const SizedBox(height: 12),
                    SourceText(
                        (task['prompt'] as String? ?? '')
                            .replaceAll(RegExp(r'\s+'), ' '),
                        key: const ValueKey('compose-prompt'),
                        style: const TextStyle(
                            fontFamily: 'sans-serif',
                            fontSize: 13.5,
                            height: 1.7,
                            color: Color(0xff3a352c))),
                    if (task['chartSeries'] != null) ...[
                      const SizedBox(height: 14),
                      WritingSourceChart(task: task)
                    ],
                    if (task['chartDesc'] != null) ...[
                      const SizedBox(height: 20),
                      const SourceText('Data/chart description',
                          style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: SurgoColors.ink)),
                      const SizedBox(height: 10),
                      SourceText(task['chartDesc'],
                          style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.7,
                              color: Color(0xff6a6459))),
                    ],
                  ])),
        ]));
  }

  Widget _editor() {
    final wc =
        '${WritingController.words(c.draft)} words / ${c.task['minWords'] ?? 250}words';
    return Container(
        key: const ValueKey('compose-editor'),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        decoration: composeCardDecoration(),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Align(
              alignment: Alignment.centerLeft,
              child: Container(
                  key: const ValueKey('compose-clock-box'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                      color: const Color(0xfffdecef),
                      borderRadius: BorderRadius.circular(13)),
                  child: Text(clock,
                      key: const ValueKey('compose-clock'),
                      style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xffe8607d))))),
          const SizedBox(height: 14),
          Expanded(
              child: TextField(
                  key: const ValueKey('essay-input'),
                  controller: text,
                  maxLines: null,
                  minLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  cursorColor:SurgoColors.ink,cursorWidth:1,
                  style: const TextStyle(
                      fontFamily: 'VioletSans',
                      fontSize: 14,
                      fontWeight:FontWeight.w400,letterSpacing:0,
                      height: 1.7,
                      color: SurgoColors.ink),
                  decoration: InputDecoration(
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: Translator.instance
                              .translate('在此输入你的答案…', c.state.lang) ??
                          '在此输入你的答案…',
                      hintStyle: const TextStyle(color: Color(0xffb8b2a6))),
                  onChanged: (v) => setState(() {
                        c.draft = v;
                        countChanged = true;
                      }))),
          const SizedBox(height: 10),
          Align(
              alignment: Alignment.centerRight,
              child: Container(
                  key: const ValueKey('compose-word-count'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                      color: const Color(0xfff4f2ef),
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    SvgPicture.string(
                        '<svg viewBox="0 0 24 24" fill="none" stroke="#6a6459" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M16.5 4.5l3 3L8 19H5v-3z"/></svg>',
                        width: 16,
                        height: 16),
                    const SizedBox(width: 8),
                    Flexible(
                        child: Text(
                            countChanged
                                ? wc
                                : (Translator.instance
                                        .translate(wc, c.state.lang) ??
                                    wc),
                            style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff6a6459)))),
                  ]))),
        ]));
  }
}
