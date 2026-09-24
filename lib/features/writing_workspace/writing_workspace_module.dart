import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import 'writing_controller.dart';
import 'writing_session_view.dart';
import 'writing_plan_view.dart';
import 'writing_compose_view.dart';

Widget? buildWritingWorkspacePage(SurgoPage page) => [
      SurgoPage.writingSession,
      SurgoPage.writingPlan,
      SurgoPage.writingCompose,
    ].contains(page)
        ? WritingWorkspacePage(page: page)
        : null;

/// The shell's page+revision key reproduces source go() lifecycle. Timer and
/// editor lifetime belong only to WritingComposeView, never planner/confirmation.
class WritingWorkspacePage extends StatelessWidget {
  const WritingWorkspacePage({super.key, required this.page});
  final SurgoPage page;
  @override
  Widget build(BuildContext context) {
    final controller = WritingController(context.read<AppState>());
    if (page == SurgoPage.writingSession) {
      return WritingSessionView(controller: controller);
    }
    if (page == SurgoPage.writingPlan) {
      return WritingPlanView(controller: controller);
    }
    return WritingComposeView(controller: controller);
  }
}
