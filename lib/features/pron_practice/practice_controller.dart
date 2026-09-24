/// Mirrors prMic/psMic/pr2Mic demo state: the H5 does NOT capture microphone
/// audio here. It only starts a timer and requests a self-assessment.
class PracticeRecording {
  bool recording = false, done = false, judged = false, ok = false;
  int seconds = 0;
  Map<String, dynamic> get sourceState => {
        'rec': recording,
        'done': done,
        'sec': seconds,
        if (judged) 'judged': true,
        if (judged) 'ok': ok
      };
}

class PracticeController {
  PracticeController(
      {required this.sentence, Map<int, PracticeRecording>? previous})
      : records = previous ?? {};
  final bool sentence;
  final Map<int, PracticeRecording> records;
  int? speaking;
  int get limit => sentence ? 30 : 15;
  PracticeRecording at(int i) =>
      records.putIfAbsent(i, () => PracticeRecording());
  void mic(int i) {
    final item = at(i);
    if (item.recording) {
      _stop(item);
      return;
    }
    for (final record in records.values) {
      if (record.recording) _stop(record);
    }
    records[i] = PracticeRecording()..recording = true;
  }

  void _stop(PracticeRecording r) {
    r.recording = false;
    r.done = true;
    r.judged = false;
    r.seconds = r.seconds == 0 ? 1 : r.seconds;
  }

  void tick() {
    for (final r in records.values) {
      if (!r.recording) continue;
      r.seconds++;
      if (r.seconds >= limit) _stop(r);
    }
  }

  void judge(int i, bool ok) {
    final r = at(i);
    r.recording = false;
    r.done = true;
    r.judged = true;
    r.ok = ok;
  }
}

const practiceWords = [
  ['library', '/ˈlaɪbrəri/', 'n. 图书馆'],
  ['relevant', '/ˈreləvənt/', 'adj. 相关的']
];
const practiceSentence = 'Larry really likes reading in the library.';
