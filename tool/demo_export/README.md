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
6. **声音。** 原型里听力的播放是计时器走进度、口语的录音是计时器计秒，包里没有一个音频文件。演示包把后端
   存着的真音频带上（听力原音频、考官提问、学员的作答录音），页面有这份数据就真的放；**录音仍是模拟的**，
   不开麦克风（演示不调接口、不打分，录了也没有去处）。号主已同意公开作答录音（owner 2026-09-30）。

## 模块

- 本目录下除 `export.cjs`、`db.cjs`、`text.cjs`、`media.cjs` 外，每个 `.cjs` 是一个模块（自动发现）：
  `exports.build(config)` 返回 `{ 'questions.json': 替换部分, … }`。对象逐键合并，数组和标量整体替换。
- 要导哪些作答写在模块文件头（`ielts_attempts.id`、各种 session id），挑已完成、结果完整的；
  `demo.config.json` 只放学员前缀。
- 参考 `writing.cjs`（雅思写作：题目、柱状图、规划、评分页、批注、母语负迁移）；各模块管哪些页面写在
  它自己的文件头。
- 题图：模块返回的值是 Buffer 就是二进制文件（`{ 'fig_xxx.jpg': 字节 }`），原样写进 `demo_data/`，构建时和
  JSON 一起盖进 `assets/data/`，页面用 `assets/data/fig_xxx.jpg`。图用 `media.cjs` 读：题目里内嵌的
  base64（`inline`），或后端文件存储里的对象（`stored`，只读 `docker exec surgo-app cat`），先按库里记的
  sha256 / 大小核对原图，再缩到 1200 宽、转成 JPEG（原图一张 2.5 MB；这一步要本机有 python + Pillow）。
  文件名里不许带库里的 id。JSON 里记 `figure: { asset, width, height, alt }`（`media.cjs` 的 `figure`，
  宽高是原图像素，页面只用它的比例），页面见 `lib/features/ielts_reading/exam_figure.dart`；没有 `figure`
  时页面画原型自带的示意图。
- 音频：和题图一样以 Buffer 返回（`{ 'aud_xxx.mp3': 字节 }`），JSON 里记 `{ asset, sec }`（`media.cjs` 的
  `clip`）。字节从哪来：后端文件存储里的对象（`object`，按库里记的 sha256 / 大小核对），或后端朗读缓存里按
  「音色 + 原文」寻址的那一份（`spoken`，旧版听力和雅思考官提问没有单独存档，只有它）。再过一遍 `audio`：
  MP3 原样带走，学员录音（WAV）转成单声道 48 kbps 的 MP3，`cut` 可以只取整场录音里的一轮；`sec` 是把成品
  解码一遍量出来的时长（要本机 PATH 上有 ffmpeg）。
  页面用 `lib/widgets/demo_audio.dart` 的 `demoAudio`：全站共用一个 `<audio>`（手机上必须这样，原因写在
  `demo_audio_web.dart` 的类注释里），同一时间只放一段。约定：
  - 数据里有 `{ asset, sec }` 且 `demoAudio.available`（网页）才走真音频；否则（原型数据、widget 测试）
    走页面原来的计时模拟，一行都不改。参考 `lib/features/ielts_listening/listening_data.dart`。
  - 进度、是否在放、是否放完都读 `demoAudio`（`position` / `playing` / `ended`），别自己另算一份；
    被浏览器拦下或文件加载失败时它按 `sec` 空走进度、照常 `ended`（`silent` 为 true），页面不会卡住。
  - 离开页面（`dispose`）调 `demoAudio.stop()`。
  - 考官提问：题库 `ielts.speaking.examinerAudio`（题目原文 → `{ asset, sec }`），
    `NativeOralSpeech` 见到就放它、不用浏览器朗读；放不出声（或浏览器朗读 2.5 秒还没开始）就把题目文字
    显示出来，流程照走（`test/speaking_unheard_test.dart`）。

## 验证

1. `node tool/demo_export/export.cjs`
2. 路由审计：141 个页面 × 中英两种界面，查报错、溢出、一直转圈和占位页。用真实数据跑，跑完换回原型数据：

   ```bash
   keep=$(mktemp -d); cp -r assets/data/. "$keep/"; cp -r demo_data/. assets/data/
   flutter test test/route_bilingual_audit_test.dart; e=$?
   rm -rf assets/data; mkdir -p assets/data; cp -r "$keep/." assets/data/; rm -rf "$keep"; echo "exit=$e"
   ```

   每个页面显示了哪些文字在 `build/audit/bilingual_routes.json`，可以核对真实数据有没有上屏。

   真实数据比原型大。JSON 到 50 KB（51200 字节）时 `rootBundle.loadString` 改用 isolate 解码，审计的假时钟
   等不到结果（网页上没有这回事）：进页面才加载这份 JSON 的页面会一直转圈，审计报
   `indeterminateIndicators`。把那一处加载改成 `rootBundle.load` + `utf8.decode`
   （例：`lib/features/tf_reading_mock/controller.dart`）。
3. 原型数据下（不覆盖）跑相关页面的测试：`flutter test -j 2 test/<相关>_test.dart`。
4. 看图：同第 2 步先覆盖，`flutter build web --release --no-web-resources-cdn -t lib/main_visual_audit.dart -o build/audit-web`，
   换回原型数据，再把 `build/web/fonts` 拷进 `build/audit-web/` 后起静态服务。网址参数见
   `lib/main_visual_audit.dart`，比如 `?route=writingFeedback&review=1-mark&lang=en`。Windows 下别从长路径
   （比如系统临时目录）起服务：兜底字体的文件名很长，整条路径超过 260 个字符会 404。
