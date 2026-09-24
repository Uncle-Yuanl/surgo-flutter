import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../vocab_quiz/vocab_done_view.dart';
import 'vocab_pron_study_view.dart';

/// Original six static pages: read → recording → judge for each of two words.
/// No recording permission, timer or automatic scoring exists in the source.
/// Speaker and manual fallback text have no source handlers. Keep them inert.
enum VocabPronPhase { read, recording, judge }

class VocabPronStudyData {
  const VocabPronStudyData(
      {required this.route,
      required this.word,
      required this.ipa,
      required this.example,
      required this.barPct,
      required this.progress,
      required this.phase,
      required this.forward,
      this.retake});
  final SurgoPage route;
  final String word, ipa;
  final String? example;
  final double barPct;
  final String progress;
  final VocabPronPhase phase;
  final SurgoPage forward;
  final SurgoPage? retake;
}

/// Verbatim fixed data and route targets from app.js 3204–3370.
final Map<SurgoPage, VocabPronStudyData> kVocabPronStudyData = {
  SurgoPage.vocabPronStudy: const VocabPronStudyData(
      route: SurgoPage.vocabPronStudy,
      word: 'Identify',
      ipa: '/aɪˈden.tɪ.faɪ/',
      example:
          'The study aimed to identify the main factors that discourage people from cycling to work.',
      barPct: .5,
      progress: '1/2 · 发音复习',
      phase: VocabPronPhase.read,
      forward: SurgoPage.vocabPronStudy2),
  SurgoPage.vocabPronStudy2: const VocabPronStudyData(
      route: SurgoPage.vocabPronStudy2,
      word: 'Identify',
      ipa: '/aɪˈden.tɪ.faɪ/',
      example:
          'The study aimed to identify the main factors that discourage people from cycling to work.',
      barPct: .5,
      progress: '1/2 · 发音复习',
      phase: VocabPronPhase.recording,
      forward: SurgoPage.vocabPronStudy3),
  SurgoPage.vocabPronStudy3: const VocabPronStudyData(
      route: SurgoPage.vocabPronStudy3,
      word: 'Identify',
      ipa: '/aɪˈden.tɪ.faɪ/',
      example:
          'The study aimed to identify the main factors that discourage people from cycling to work.',
      barPct: .5,
      progress: '1/2 · 发音复习',
      phase: VocabPronPhase.judge,
      forward: SurgoPage.vocabPronStudyB,
      retake: SurgoPage.vocabPronStudy),
  SurgoPage.vocabPronStudyB: const VocabPronStudyData(
      route: SurgoPage.vocabPronStudyB,
      word: 'Adapt',
      ipa: '/əˈdæpt/',
      example: null,
      barPct: 1,
      progress: '2/2 · 发音复习',
      phase: VocabPronPhase.read,
      forward: SurgoPage.vocabPronStudyB2),
  SurgoPage.vocabPronStudyB2: const VocabPronStudyData(
      route: SurgoPage.vocabPronStudyB2,
      word: 'Adapt',
      ipa: '/əˈdæpt/',
      example: null,
      barPct: 1,
      progress: '2/2 · 发音复习',
      phase: VocabPronPhase.recording,
      forward: SurgoPage.vocabPronStudyB3),
  SurgoPage.vocabPronStudyB3: const VocabPronStudyData(
      route: SurgoPage.vocabPronStudyB3,
      word: 'Adapt',
      ipa: '/əˈdæpt/',
      example: null,
      barPct: 1,
      progress: '2/2 · 发音复习',
      phase: VocabPronPhase.judge,
      forward: SurgoPage.vocabPronDone,
      retake: SurgoPage.vocabPronStudyB),
};

Widget? buildVocabPronStudyPage(SurgoPage page) {
  final data = kVocabPronStudyData[page];
  if (data != null) {
    return VocabPronStudyPage(data: data);
  }
  if (page == SurgoPage.vocabPronDone) {
    return const VocabPronDonePage();
  }
  return null;
}

class VocabPronStudyPage extends StatelessWidget {
  const VocabPronStudyPage({super.key, required this.data});
  final VocabPronStudyData data;
  @override
  Widget build(BuildContext context) => VocabPronStudyView(data: data);
}

class VocabPronDonePage extends StatelessWidget {
  const VocabPronDonePage({super.key});
  @override
  Widget build(BuildContext context) =>
      const VocabDoneView(pronunciation: true);
}
