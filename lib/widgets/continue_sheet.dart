import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app/app_state.dart';
import '../app/i18n.dart';
import '../app/routes.dart';
import '../features/ielts_listening/listening_data.dart';
import '../theme/tokens.dart';
import '../widgets/t.dart';

/// 首页「继续学习」弹窗 —— 端口自原型 `app.js` 12224-12270 的
/// `CONTINUE_ITEMS` / `renderContinue` / `jumpContinue`，CSS 见 `.cont-*`
/// （index.html 404-421）。
///
/// 5 条固定项从 [assets/data/continue.json]（由 tool/export_continue.cjs 逐字导出）
/// 载入，顺序、文案、进度、目标页均与源一致。ALL / Daily training / Mock exams
/// 三个分页按 `it.tab` 过滤，过滤后**第一条**加「最推荐」标（源 `idx===0?'rec'`）。
///
/// 弹窗自身没有跳转能力（原型是散落全局函数 `go(...)`）；这里用嵌套 Navigator
/// （`useRootNavigator:false`）弹出，点击项目时先复刻 `jumpContinue` 的状态写入，
/// 再交给上层 [AppState.go]。父层负责在别处挂上入口回调。
class ContinueData {
  ContinueData(this.raw);
  final Map<String, dynamic> raw;
  static ContinueData? cache;
  static Future<ContinueData> load() async => cache ??= ContinueData(
      jsonDecode(await rootBundle.loadString('assets/data/continue.json'))
          as Map<String, dynamic>);
  List<Map<String, dynamic>> get items =>
      (raw['items'] as List).cast<Map<String, dynamic>>();
}

/// 对应原型 `openContinueSheet()`：`continueTab='all'; continuePick=0; renderContinue();`
/// 弹出嵌套 Navigator 的模态卡片。返回的 Future 在弹窗关闭后完成。
Future<void> showContinueSheet(BuildContext context) async {
  await IeltsListeningData.load();
  if(!context.mounted)return;
  return showDialog<void>(
    context: context,
    useRootNavigator: false,
    barrierColor: Colors.black54,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<AppState>(),
      child: const _ContinueSheet(),
    ),
  );
}

/// 复刻 `jumpContinue(i)`：先 closeModal，再按 go 目标直接进入作答页的未完成题目。
///
/// - readingDaily：清空 selReadType/readIdx/typeIdx/readDone/typeDone，按 pct 估算
///   已答题数写入 readDone，readIdx 落到未完成处，跳 readingSession。
/// - listeningDaily：清空 lisDone，按 pct 估算已答写入 lisDone，lisIdx 落位，跳 listeningSession。
/// - writingDaily：直接跳 writingSession。
/// - 其余（speakingDaily 等）：go(it.go) —— 源里没有特判，照跳目标页本身。
///
/// 题目总数取当前 READ_PARTS/LQS 语义：阅读=当前考试 reading.daily.questions 数，
/// 听力=当前 lisPart（默认 s1）的 qs 数。与原生 ReadingController/ListeningController
/// 读取的 session 键（readIdx/readDone/typeIdx/typeDone/selReadType、lisIdx/lisDone）一致。
void jumpContinue(BuildContext context, Map<String, dynamic> it) {
  final app = context.read<AppState>();
  // closeModal()：先关掉当前嵌套 Navigator 的弹窗。
  Navigator.of(context, rootNavigator: false).pop();
  final go = it['go'] as String;
  final pct = (it['pct'] as num).toDouble();
  if (go == 'readingDaily') {
    // selReadType=null; readIdx=0; typeIdx=0; readDone.clear(); typeDone.clear();
    app.session['selReadType'] = null;
    app.session['readIdx'] = 0;
    app.session['typeIdx'] = 0;
    final readDone = <int>{};
    app.session['readDone'] = readDone;
    app.session['typeDone'] = <int>{};
    // const total=READ_PARTS.reduce(...) —— 全量 daily 题数（flatQuestions().length）。
    final questions = QuestionBank.instance
        .skill('reading', app.examType)['daily']?['questions'] as List? ??
        const [];
    final total = questions.length;
    final done = (total * (pct / 100)).round();
    for (var k = 0; k < done; k++) {
      readDone.add(k);
    }
    // readIdx=Math.min(done,total-1)
    app.session['readIdx'] = total == 0 ? 0 : (done < total - 1 ? done : total - 1);
    app.go(SurgoPage.readingSession);
  } else if (go == 'listeningDaily') {
    // lisIdx=0; lisDone.clear();
    app.session['lisIdx'] = 0;
    final lisDone = <int>{};
    app.session['lisDone'] = lisDone;
    // const done=Math.round(LQS.length*(pct/100)) —— LQS=当前 Part 的 qs。
    final lqs = _currentLqs(app);
    final total = lqs.length;
    final done = (total * (pct / 100)).round();
    for (var k = 0; k < done; k++) {
      lisDone.add(k);
    }
    // lisIdx=Math.min(done,LQS.length-1)
    app.session['lisIdx'] = total == 0 ? 0 : (done < total - 1 ? done : total - 1);
    app.go(SurgoPage.listeningSession);
  } else if (go == 'writingDaily') {
    // go('writingSession')
    app.go(SurgoPage.writingSession);
  } else {
    // else go(it.go) —— 例如 speakingDaily 直接进 speakingSession（源无特判）。
    final page = SurgoPageX.fromKey(go);
    if (page != null) app.go(page); // 源 go(id) 里 if(!V[id])return 的静默忽略语义。
  }
}

/// 对应 `LQS`：`LQS=LPARTS[lisPart].qs`，`setLisPart` 里 `lisPart=LPARTS[k]?k:'s1'`。
List _currentLqs(AppState app) {
  final data = IeltsListeningData.cache?.raw;
  if (data == null) return const [];
  final parts = data['parts'] as Map<String, dynamic>?;
  if (parts == null) return const [];
  var part = app.session['lisPart'] as String? ?? 's1';
  if (parts[part] == null) part = 's1';
  final qs = (parts[part] as Map<String, dynamic>?)?['qs'] as List?;
  return qs ?? const [];
}

// The sheet awaits the actual shared source export before allowing selection.

class _ContinueSheet extends StatefulWidget {
  const _ContinueSheet();
  @override
  State<_ContinueSheet> createState() => _ContinueSheetState();
}

class _ContinueSheetState extends State<_ContinueSheet> {
  // 源：let continueTab='all', continuePick=0;（openContinueSheet 里重置）
  String continueTab = 'all';
  int continuePick = 0;
  ContinueData? data;

  @override
  void initState() {
    super.initState();
    ContinueData.load().then((d) {
      if (mounted) setState(() => data = d);
    });
  }

  // 源 setContinueTab(t){ continueTab=t; renderContinue(); }
  void setContinueTab(String t) => setState(() => continueTab = t);

  @override
  Widget build(BuildContext context) {
    final d = data;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: SurgoRadius.dialogAll),
      child: d == null
          ? const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()))
          : _body(d),
    );
  }

  Widget _body(ContinueData d) {
    // 源 renderContinue：
    //   const list=CONTINUE_ITEMS.map((it,i)=>({it,i}))
    //     .filter(x=>continueTab==='all'||x.it.tab===continueTab);
    //   if(!list.some(x=>x.i===continuePick) && list.length) continuePick=list[0].i;
    final all = d.items;
    final list = <({Map<String, dynamic> it, int i})>[];
    for (var i = 0; i < all.length; i++) {
      final it = all[i];
      if (continueTab == 'all' || it['tab'] == continueTab) {
        list.add((it: it, i: i));
      }
    }
    if (!list.any((x) => x.i == continuePick) && list.isNotEmpty) {
      continuePick = list.first.i;
    }
    return Padding(
      // .cont-sheet 承 .sheet 内边距（原型抽屉留白），此处取弹窗常用 24。
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // .cont-hd：标题 + 关闭 ✕
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: T('Which one do you want to continue ?',
                    style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontSize: 16, // css 18 → 16
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        height: 1.25)),
              ),
              const SizedBox(width: 12),
              // onclick="closeModal()"
              GestureDetector(
                key: const ValueKey('continue-close'),
                onTap: () =>
                    Navigator.of(context, rootNavigator: false).pop(),
                child: const Text('✕',
                    style: TextStyle(fontSize: 16, color: SurgoColors.muted)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // .cont-tabs：ALL / Daily training / Mock exams
          Row(children: [
            Expanded(child:_tab('all', 'ALL')),
            const SizedBox(width: 10),
            Expanded(child:_tab('daily', 'Daily training')),
            const SizedBox(width: 10),
            Expanded(child:_tab('mock', 'Mock exams')),
          ]),
          const SizedBox(height: 18),
          // .cont-list
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var idx = 0; idx < list.length; idx++) ...[
                    if (idx > 0) const SizedBox(height: 12),
                    _item(list[idx].it, list[idx].i, idx == 0),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // .cont-tab / .cont-tab.on
  Widget _tab(String key, String label) {
    final on = continueTab == key;
    return GestureDetector(
      key: ValueKey('continue-tab-$key'),
      onTap: () => setContinueTab(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: on ? SurgoColors.yellow : const Color(0xFFF6EFDD),
          borderRadius: BorderRadius.circular(SurgoRadius.pill),
        ),
        child: T(label,
            style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                fontSize: 11, // css 13 → 11
                fontWeight: FontWeight.w800,
                color: on ? const Color(0xFF3A2E00) : const Color(0xFFB8A86A))),
      ),
    );
  }

  // .cont-item（idx===0 → .rec，且显示「最推荐」角标）
  Widget _item(Map<String, dynamic> it, int sourceIndex, bool rec) {
    return GestureDetector(
      key: ValueKey('continue-item-$sourceIndex'),
      // onclick="jumpContinue(i)" —— 传源索引 i，非过滤后下标。
      onTap: () => jumpContinue(context, it),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: rec ? SurgoColors.yellow : SurgoColors.line,
            width: rec ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(SurgoRadius.cardMd),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(children: [
              // .cont-ic
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: SurgoColors.yellowTint,
                  borderRadius: BorderRadius.circular(SurgoRadius.chip),
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  // 源 ic 为 'assets/ic3_xxx.png'；本工程资源在 assets/images/。
                  _assetPath(it['ic'] as String),
                  width: 26,
                  height: 26,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.menu_book, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              // .cont-txt
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // .cont-name（题目内容，原始 Text，不过翻译）
                    Text(it['name'] as String,
                        style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                            fontSize: 14, // css 16 → 14
                            fontWeight: FontWeight.w800,
                            color: SurgoColors.ink)),
                    const SizedBox(height: 3),
                    // .cont-kicker
                    Text(it['kicker'] as String,
                        style: const TextStyle(
                            fontSize: 10, // css 11 → 10（触底）
                            fontWeight: FontWeight.w600,
                            color: SurgoColors.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // .cont-pct
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3ECDB),
                  borderRadius: BorderRadius.circular(SurgoRadius.chipSm),
                ),
                child: Text('${it['pct']}%',
                    style: const TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                        fontSize: 10, // css 12 → 10
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF9A7A00))),
              ),
            ]),
            // .cont-rec「最推荐」角标（top:-9px;right:14px）
            if (rec)
              Positioned(
                top: -9 - 12, // 抵消 item 的垂直内边距，贴到边框上沿
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: SurgoColors.yellow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const T('最推荐',
                      style: TextStyle(fontFamily: 'Outfit', fontFamilyFallback: SurgoFontFamily.fallback, 
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3A2E00))),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 'assets/ic3_writing.png' → 'assets/images/ic3_writing.png'
  String _assetPath(String ic) {
    final name = ic.split('/').last;
    return 'assets/images/$name';
  }
}
