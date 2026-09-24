import 'package:flutter/material.dart';
import '../../app/routes.dart';
import 'vocab_home_view.dart';

// Fixed source tier data and public entry retained; visual layout lives in view.
class VocabTier {
  const VocabTier(this.title, this.count, this.percent, this.cta, this.route);
  final String title, count, cta;
  final int percent;
  final SurgoPage route;
}

/// Verbatim from `vocabHomeView` `tiers`.
const List<VocabTier> kVocabTiers = [
  VocabTier('Tier 1 · 必备', '226 词', 46, '继续学习', SurgoPage.vocabTier1),
  VocabTier('Tier 2 · 核心', '1302 词', 0, '开始学习', SurgoPage.vocabTier2),
  VocabTier('Tier 3 · 重要', '1180 词', 0, '开始学习', SurgoPage.vocabTier3),
  VocabTier('Tier 4 · 拓展', '3221 词', 0, '开始学习', SurgoPage.vocabTier4),
];

// -------------------------------------------------------------------- entry

/// Router entry for the vocab-home native page. Returns [VocabHomePage] for
/// `vocab`, or `null` for any page this module does not own (mirrors the
/// prototype `if(!V[id]) return;`).
Widget? buildVocabHomePage(SurgoPage page) =>
    page == SurgoPage.vocab ? const VocabHomePage() : null;

class VocabHomePage extends StatelessWidget {
  const VocabHomePage({super.key});
  @override
  Widget build(BuildContext context) => const VocabHomeView();
}
