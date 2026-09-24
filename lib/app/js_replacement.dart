/// JavaScript String.replace(RegExp, string) semantics for source i18n rules.
/// Dart replaceFirst does not interpolate $1; use match-aware expansion instead.
String jsReplace(String input, RegExp expression, String replacement,
    {bool global = false}) {
  var replaced = false;
  return input.replaceAllMapped(expression, (match) {
    if (replaced && !global) return match[0]!;
    replaced = true;
    final out = StringBuffer();
    for (var i = 0; i < replacement.length; i++) {
      if (replacement[i] != r'$' || i + 1 == replacement.length) {
        out.write(replacement[i]);
        continue;
      }
      final next = replacement[i + 1];
      if (next == r'$') { out.write(r'$'); i++; continue; }
      if (next == '&') { out.write(match[0]); i++; continue; }
      if (next == '`') { out.write(input.substring(0, match.start)); i++; continue; }
      if (next == "'") { out.write(input.substring(match.end)); i++; continue; }
      if (next == '<' && match is RegExpMatch && match.groupNames.isNotEmpty) {
        final end = replacement.indexOf('>', i + 2);
        if (end != -1) {
          final name = replacement.substring(i + 2, end);
          out.write(match.groupNames.contains(name) ? match.namedGroup(name) ?? '' : '');
          i = end;
          continue;
        }
      }
      final first = int.tryParse(next);
      if (first != null) {
        var number = first;
        var consumed = 1;
        if (i + 2 < replacement.length) {
          final second = int.tryParse(replacement[i + 2]);
          if (second != null && first * 10 + second > 0 && first * 10 + second <= match.groupCount) {
            number = first * 10 + second;
            consumed = 2;
          }
        }
        if (number > 0 && number <= match.groupCount) {
          out.write(match[number] ?? '');
          i += consumed;
          continue;
        }
      }
      out.write(r'$');
    }
    return out.toString();
  });
}

RegExp jsRegExp(String pattern, String flags) => RegExp(pattern,
    caseSensitive: !flags.contains('i'),
    multiLine: flags.contains('m'),
    dotAll: flags.contains('s'),
    unicode: flags.contains('u'));
