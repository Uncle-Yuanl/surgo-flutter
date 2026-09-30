import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import 'review_header.dart';
import 'review_content.dart';
import 'review_widgets.dart';

/// Source fixed demo assessment, never grading the user's draft.
class WritingReviewPage extends StatefulWidget {
  const WritingReviewPage({super.key});
  @override
  State<WritingReviewPage> createState() => _WritingReviewPageState();
}

class _WritingReviewPageState extends State<WritingReviewPage> {
  Map<String, dynamic>? data;
  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/data/writing_review.json').then((raw) {
      if (mounted) {
        setState(() => data = jsonDecode(raw));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = data;
    if (d == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final app = context.watch<AppState>(),
        task = appTask(context),
        l1 = context.watch<AppState>().session['wfTab'] == 'l1';
    final content =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      WritingReviewHeader(task: task, l1: l1, data: d),
      WritingReviewContent(data: d, task: task, l1: l1, app: app),
      Padding(
          padding: const EdgeInsets.only(top: 4),
          child: ReviewButton('回到首页',
              key: const ValueKey('review-end-home'),
              onTap: () => app.go(SurgoPage.ielts))),
    ]);
    return LayoutBuilder(builder: (context, bounds) {
      if (!bounds.hasBoundedHeight) {
        return content;
      }
      return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
              key: const ValueKey('writing-review-scroll'),
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
              child: content));
    });
  }

  int appTask(BuildContext context) =>
      context.read<AppState>().session['wfTask'] as int? ?? 1;
}
