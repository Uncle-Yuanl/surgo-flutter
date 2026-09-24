import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../app/routes.dart';
import '../pron_practice/practice_widgets.dart';

/// H5 .read-page: fixed nav, only .read-scroll scrolls. Natural-height fallback
/// retains compatibility for embedding the body in a team's existing scroller.
class PronPageFrame extends StatelessWidget {
  const PronPageFrame({super.key, required this.back, required this.child});
  final SurgoPage back;
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, bounds) {
        final nav =
            PracticeNav(onBack: () => context.read<AppState>().go(back));
        if (!bounds.hasBoundedHeight) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [nav, child]);
        }
        return Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  nav,
                  Expanded(
                      child: SingleChildScrollView(
                          key: const ValueKey('pron-page-scroll'),
                          child: child)),
                ]));
      });
}
