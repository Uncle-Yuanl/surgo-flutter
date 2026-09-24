import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads every bundled family, so geometry assertions measure real glyph
/// metrics instead of the square fallback test font.
///
/// Headings use Outfit and body/question text uses PingFang SC (user request,
/// 2026-09-24); VioletSans stays for the places that keep the source webfont.
/// PingFang is an Apple system font resolved by name at runtime — there is no
/// file to load, so widget tests measure it through the default test font.
Future<void> loadSurgoTestFonts() async {
  const families = <String, List<String>>{
    'VioletSans': ['assets/fonts/violet-sans.ttf'],
    'Outfit': [
      'assets/fonts/Outfit-Regular.ttf',
      'assets/fonts/Outfit-Medium.ttf',
      'assets/fonts/Outfit-SemiBold.ttf',
      'assets/fonts/Outfit-Bold.ttf',
      'assets/fonts/Outfit-Black.ttf',
    ],
  };
  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    for (final asset in entry.value) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
}
