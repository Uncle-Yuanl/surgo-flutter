# 演示用真实数据（tool/demo_export）

把本地后端库里演示学员的真实作答导出成 `demo_data/*.json`。Vercel 构建时
（`vercel.json` → `tool/vercel_build.sh --demo-data`）把它盖到 `assets/data/` 上；演示页面只读这些
JSON，不调接口，也不现场生成任何内容。

运行：`node tool/demo_export/export.cjs`（需要本机 docker 里后端栈的 `surgo-postgres`）。

## 规矩

1. **只读库。** `db.cjs` 的每条 SQL 都包在 `BEGIN READ ONLY` 里。不调后端 HTTP 接口：任何带令牌的请求
   都会写 `users.last_login_at`，模考的列表 / 详情还会清扫过期场次、封卷并触发 AI 评分。
2. **`assets/data/` 是原型数据，不改。** 同事的测试跑的是它。真实数据只进 `demo_data/`，由导出脚本生成，别手改。
3. **个人信息。** 号主已同意公开作答内容（owner 2026-09-30），但输出里不许有姓名、邮箱、手机号和库里的
   各种 id；`export.cjs` 检查不过就一个文件都不写。
4. **语言。** 后端存了中英两份的，输出 `[英文, 中文]`（`text.cjs` 的 `pair`），页面的 `T` 按界面语言取一项；
   只存了英文的保持原文，不机翻（owner 定）。`SourceText` 只收字符串，别给它传一对。
5. **页面里写死的演示值**（分数、薄弱项、学员名等）改成「JSON 有就用，没有就用原来的值」：原型数据下
   渲染不变，同事的测试不用改。真实数据缺的行 / 块就不画，别把不对题的字段硬塞进去。
6. 听力、口语的播放和录音在原型里本来就是模拟的，不接真音频。

## 模块

- 本目录下除 `export.cjs`、`db.cjs`、`text.cjs`、`media.cjs` 外，每个 `.cjs` 是一个模块（自动发现）：
  `exports.build(config)` 返回 `{ 'questions.json': 替换部分, … }`。对象逐键合并，数组和标量整体替换。
- 要导哪些作答写在模块文件头（`ielts_attempts.id`、各种 session id），挑已完成、结果完整的；
  `demo.config.json` 只放学员前缀。
- 参考 `writing.cjs`（雅思写作：题目、柱状图、规划、评分页、批注、母语负迁移）。
- 题图：模块返回的值是 Buffer 就是二进制文件（`{ 'fig_xxx.png': 字节 }`），原样写进 `demo_data/`，构建时和
  JSON 一起盖进 `assets/data/`，页面用 `assets/data/fig_xxx.png`。图用 `media.cjs` 读：题目里内嵌的
  base64（`inline`），或后端文件存储里的对象（`stored`，只读 `docker exec surgo-app cat`），都按库里记的
  sha256 / 大小核对，不转码。文件名里不许带库里的 id。JSON 里记 `figure: { asset, width, height, alt }`
  （`media.cjs` 的 `figure`），页面见 `lib/features/ielts_reading/exam_figure.dart`；没有 `figure` 时页面
  画原型自带的示意图。

## 验证

1. `node tool/demo_export/export.cjs`
2. 路由审计：141 个页面 × 中英两种界面，查报错、溢出、一直转圈和占位页。用真实数据跑，跑完换回原型数据：

   ```bash
   keep=$(mktemp -d); cp -r assets/data/. "$keep/"; cp -r demo_data/. assets/data/
   flutter test test/route_bilingual_audit_test.dart; e=$?
   rm -rf assets/data; mkdir -p assets/data; cp -r "$keep/." assets/data/; rm -rf "$keep"; echo "exit=$e"
   ```

   每个页面显示了哪些文字在 `build/audit/bilingual_routes.json`，可以核对真实数据有没有上屏。
   页面一直转圈多半是它的 JSON 超过了 50 KB：`rootBundle.loadString` 对 50 KB 以上的文件另起 isolate
   解码，widget 测试的假时钟等不到（网页上没有这回事）。页面自己懒加载的文件超了，就改成读字节直接解码
   （见 `lib/features/ielts_reading/reading_controller.dart` 的 `ReadingData.load`）。
3. 原型数据下（不覆盖）跑相关页面的测试：`flutter test -j 2 test/<相关>_test.dart`。
4. 看图：同第 2 步先覆盖，`flutter build web --release --no-web-resources-cdn -t lib/main_visual_audit.dart -o build/audit-web`，
   换回原型数据，再把 `build/web/fonts` 拷进 `build/audit-web/` 后起静态服务。网址参数见
   `lib/main_visual_audit.dart`，比如 `?route=writingFeedback&review=1-mark&lang=en`。Windows 下别从长路径
   （比如系统临时目录）起服务：兜底字体的文件名很长，整条路径超过 260 个字符会 404。
