import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:surgo_flutter/app/app_state.dart';
import 'package:surgo_flutter/app/i18n.dart';
import 'package:surgo_flutter/app/routes.dart';
import 'package:surgo_flutter/app/shell.dart';
import 'package:surgo_flutter/theme/app_theme.dart';
import 'package:surgo_flutter/features/vocab_quiz/vocab_quiz_module.dart';
import 'package:surgo_flutter/widgets/source_text.dart';
import 'support/fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await Translator.load();
    await QuestionBank.load();
    await loadSurgoTestFonts();
  });
  for (final entry in kVocabStudyData.entries) {
    for (final lang in UiLang.values) {
      testWidgets('${entry.key.name} ${lang.name}: source layout and actions',
          (t) async {
        await t.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => t.binding.setSurfaceSize(null));
        final app = AppState(current: entry.key, lang: lang);
        await t.pumpWidget(ChangeNotifierProvider.value(
            value: app,
            child: MaterialApp(
                theme: SurgoTheme.build(),
                home: const MediaQuery(
                    data: MediaQueryData(size: Size(390, 844)),
                    child: SurgoShell()))));
        await t.pumpAndSettle();
        final word = t
            .widget<SourceText>(find.byKey(const ValueKey('vocab-study-word')));
        expect(word.style!.fontSize, 44);
        expect(word.data, entry.value.word);
        final speaker = find.byKey(const ValueKey('vocab-study-speaker'));
        expect(t.getSize(speaker), const Size(30, 30));
        expect(
            find.ancestor(of: speaker, matching: find.byType(GestureDetector)),
            findsNothing);
        final top = t.getRect(find.byKey(const ValueKey('vocab-study-top')));
        for (final key in ['exit', 'demo', 'progress', 'count']) {
          final rect = t.getRect(find.byKey(ValueKey('vocab-study-$key')));
          expect(rect.center.dy, closeTo(top.center.dy, 1));
        }
        final card =
            t.widget<Container>(find.byKey(const ValueKey('vocab-study-card')));
        expect(card.padding,
            const EdgeInsets.symmetric(horizontal: 24, vertical: 44));
        final decoration = card.decoration as BoxDecoration;
        expect(decoration.border, isNull);
        final button = find.byKey(const ValueKey('vocab-study-reveal'));
        expect(t.getSize(button).width, lessThan(300));
        final image = find.byKey(const ValueKey('vocab-study-tip-image'));
        expect(image, entry.value.showTipIcon ? findsOneWidget : findsNothing);
        if (entry.value.showTipIcon) {
          expect(t.getSize(image), const Size(48, 48));
        }
        expect(t.takeException(), isNull);
        await t.tap(button);
        await t.pumpAndSettle();
        expect(app.current, entry.value.reveal);
        app.go(entry.key);
        await t.pumpAndSettle();
        await t.tap(find.byKey(const ValueKey('vocab-study-exit')));
        await t.pumpAndSettle();
        expect(app.current, SurgoPage.vocab);
        expect(t.takeException(), isNull);
      });
    }
  }
}
