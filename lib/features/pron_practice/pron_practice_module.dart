import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import 'practice_controller.dart';
import 'practice_content.dart';

Widget? buildPronPracticePage(SurgoPage p) => switch (p) {
      SurgoPage.pronRepeat ||
      SurgoPage.pronSentence ||
      SurgoPage.pronDone ||
      SurgoPage.pronCongrats ||
      SurgoPage.pron2Lesson ||
      SurgoPage.pron2Repeat ||
      SurgoPage.pron2Done ||
      SurgoPage.pronCongrats2 =>
        PronPracticePage(page: p),
      _ => null,
    };

class PronPracticePage extends StatefulWidget {
  const PronPracticePage({super.key, required this.page});
  final SurgoPage page;
  @override
  State<PronPracticePage> createState() => _PronPracticePageState();
}

class _PronPracticePageState extends State<PronPracticePage> {
  late final PracticeController controller;
  final tts = FlutterTts();
  Timer? timer, reset;
  bool get second => [
        SurgoPage.pron2Lesson,
        SurgoPage.pron2Repeat,
        SurgoPage.pron2Done,
        SurgoPage.pronCongrats2
      ].contains(widget.page);
  bool get sentence => widget.page == SurgoPage.pronSentence;
  String get recKey => second
      ? 'pr2Rec'
      : sentence
          ? 'psRec'
          : 'prRec';
  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    controller = PracticeController(
        sentence: sentence,
        previous: second
            ? app.session['_pr2Native'] as Map<int, PracticeRecording>?
            : null);
    if (second) app.session['_pr2Native'] = controller.records;
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(controller.tick);
      _sync();
    });
  }

  void _sync() {
    final app = context.read<AppState>();
    app.session[recKey] = sentence
        ? controller.at(0).sourceState
        : controller.records.map((k, v) => MapEntry(k, v.sourceState));
  }

  @override
  void dispose() {
    timer?.cancel();
    reset?.cancel();
    tts.stop();
    super.dispose();
  }

  Future<void> speak(int i, String word) async {
    setState(() => controller.speaking = i);
    void done() {
      if (mounted && controller.speaking == i) {
        setState(() => controller.speaking = null);
      }
    }

    reset?.cancel();
    reset = Timer(const Duration(seconds: 3), done);
    try {
      if (second) await tts.stop();
      await tts.setLanguage('en-GB');
      await tts.setSpeechRate(.85);
      tts.setCompletionHandler(done);
      tts.setErrorHandler((_) {
        done();
      });
      await tts.speak(word);
    } catch (_) {
      reset?.cancel();
      reset = Timer(const Duration(milliseconds: 900), done);
    }
  }

  void mic(int i) {
    if (second) {
      tts.stop();
      controller.speaking = null;
    }
    setState(() => controller.mic(i));
    _sync();
  }

  @override
  Widget build(BuildContext context) => PracticeContent(
      page: widget.page,
      controller: controller,
      speak: speak,
      mic: mic,
      judge: (i, ok) {
        setState(() => controller.judge(i, ok));
        _sync();
      });
}
