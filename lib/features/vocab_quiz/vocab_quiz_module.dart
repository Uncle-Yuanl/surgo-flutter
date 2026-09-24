import 'package:flutter/material.dart';
import '../../app/routes.dart';
import 'vocab_study_view.dart';
import 'vocab_test_views.dart';
import 'vocab_done_view.dart';

/// Native entry points for nine source routes. Presentation lives in separate
/// views. All fixed data, grading branches and navigation targets remain the
/// original app.js vocabTest/Study/Done behaviour; no recording or AI scoring.
class VocabStudyData {
  const VocabStudyData(
      {required this.route,
      required this.word,
      required this.ipa,
      required this.barPct,
      required this.progress,
      required this.reveal,
      required this.showTipIcon});
  final SurgoPage route;

  /// Raw content remains unchanged; SourceText applies only captured DOM-node
  /// translations, as the source applyLang does (including Identify → 识别).
  final String word, ipa;
  final double barPct;
  final String progress;
  final SurgoPage reveal;
  final bool showTipIcon;
}

final Map<SurgoPage, VocabStudyData> kVocabStudyData = {
  SurgoPage.vocabStudy: const VocabStudyData(
      route: SurgoPage.vocabStudy,
      word: 'Identify',
      ipa: '/aɪˈden.tɪ.faɪ/',
      barPct: 0.50,
      progress: '1/2 · 系统词汇复习',
      reveal: SurgoPage.vocabDetail,
      showTipIcon: true),
  SurgoPage.vocabStudy2: const VocabStudyData(
      route: SurgoPage.vocabStudy2,
      word: 'Adapt',
      ipa: '/əˈdæpt/',
      barPct: 0.666,
      progress: '2/3 · 学习中',
      reveal: SurgoPage.vocabDetail2,
      showTipIcon: false),
  SurgoPage.vocabStudy3: const VocabStudyData(
      route: SurgoPage.vocabStudy3,
      word: 'Analyse',
      ipa: '/ˈæn.əl.aɪz/',
      barPct: 1.0,
      progress: '2/2 · 系统词汇复习',
      reveal: SurgoPage.vocabDetail3,
      showTipIcon: true),
  SurgoPage.vocabStudy4: const VocabStudyData(
      route: SurgoPage.vocabStudy4,
      word: 'Context',
      ipa: '/ˈkɒn.tekst/',
      barPct: 1.0,
      progress: '1/1 · 学习中',
      reveal: SurgoPage.vocabDetail4,
      showTipIcon: true),
};

class VocabQuizOption {
  const VocabQuizOption(this.key, this.def, this.correct);
  final String key, def;
  final bool correct;
}

/// Verbatim source options. A recommends Tier 2; B/C/D and skip recommend Tier 1.
const List<VocabQuizOption> kVocabQuizOptions = [
  VocabQuizOption('A', '识别；确认；认出', true),
  VocabQuizOption('B', '适应；改编', false),
  VocabQuizOption('C', '分析', false),
  VocabQuizOption('D', '语境；背景', false),
];

SurgoPage vocabQuizTarget({required bool correct}) =>
    correct ? SurgoPage.vocabTier2 : SurgoPage.vocabTier1;

Widget? buildVocabQuizPage(SurgoPage page) {
  switch (page) {
    case SurgoPage.vocabTest:
      return const VocabTestPage();
    case SurgoPage.vocabTestQ:
      return const VocabTestQPage();
    case SurgoPage.vocabTestPass:
      return const VocabTestResultPage(pass: true);
    case SurgoPage.vocabTestFail:
      return const VocabTestResultPage(pass: false);
    case SurgoPage.vocabStudy:
    case SurgoPage.vocabStudy2:
    case SurgoPage.vocabStudy3:
    case SurgoPage.vocabStudy4:
      return VocabStudyPage(data: kVocabStudyData[page]!);
    case SurgoPage.vocabDone:
      return const VocabDonePage();
    default:
      return null;
  }
}

class VocabTestPage extends StatelessWidget {
  const VocabTestPage({super.key});
  @override
  Widget build(BuildContext context) => const VocabTestIntroView();
}

class VocabTestQPage extends StatelessWidget {
  const VocabTestQPage({super.key});
  @override
  Widget build(BuildContext context) => const VocabQuestionView();
}

class VocabTestResultPage extends StatelessWidget {
  const VocabTestResultPage({super.key, required this.pass});
  final bool pass;
  @override
  Widget build(BuildContext context) => VocabResultView(pass: pass);
}

class VocabStudyPage extends StatelessWidget {
  const VocabStudyPage({super.key, required this.data});
  final VocabStudyData data;
  @override
  Widget build(BuildContext context) => VocabStudyView(
      word: data.word,
      ipa: data.ipa,
      progress: data.progress,
      pct: data.barPct,
      reveal: data.reveal,
      showTipIcon: data.showTipIcon);
}

class VocabDonePage extends StatelessWidget {
  const VocabDonePage({super.key});
  @override
  Widget build(BuildContext context) => const VocabDoneView();
}
