import 'package:flutter/material.dart';
import 'package:surgo_flutter/features/report/learning_advice.dart';
import '../../theme/tokens.dart';

/// Simple demo app to verify LearningAdvice widget
void main() {
  runApp(const LearningAdviceDemo());
}

class LearningAdviceDemo extends StatefulWidget {
  const LearningAdviceDemo({super.key});

  @override
  State<LearningAdviceDemo> createState() => _LearningAdviceDemoState();
}

class _LearningAdviceDemoState extends State<LearningAdviceDemo> {
  String _selectedSkill = kSkillListening;
  bool _chinese = true;
  String? _lastPracticedSkill;
  int? _lastPracticedRank;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learning Advice Demo',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Learning Advice Widget Demo'),
          actions: [
            IconButton(
              icon: Text(_chinese ? 'EN' : '中'),
              onPressed: () => setState(() => _chinese = !_chinese),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_lastPracticedSkill != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Last practiced: $_lastPracticedSkill, rank: $_lastPracticedRank',
                    style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, fontWeight: FontWeight.bold),
                  ),
                ),
              LearningAdvice(
                chinese: _chinese,
                selectedSkill: _selectedSkill,
                onSelectSkill: (skill) {
                  setState(() => _selectedSkill = skill);
                },
                onPractice: (skill, rank) {
                  setState(() {
                    _lastPracticedSkill = skill;
                    _lastPracticedRank = rank;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Practice triggered: $skill, rank: $rank'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
