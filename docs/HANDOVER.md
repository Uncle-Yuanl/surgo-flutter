# SURGO 原生 Flutter 工程交接

## 交付性质

本工程是从 SURGO H5 原型重写的 **Dart 原生 Widget 工程**，不是 WebView 包装。141 个源路由均已挂载原生页面，支持中英文 UI、IELTS/TOEFL 独立练习与模考流程。

**当前是可运行的迁移工程，不是已签收的全量规则/像素保真成品。** 初始布局覆盖、数据一致性及已写的专项测试已验证；未逐一证明全部分支、非默认状态、所有反馈标注和真机媒体能力等价。已知差异与优先级见 `KNOWN_DIFFS.md`，不要把路由接入计数或测试通过率当作保真百分比。

原 H5 仍保留在兄弟目录 `surgo-mobile-new`，迁移没有修改或替换它。没有推送 Git、部署远程服务或接入评分后端。

## 工程与运行

本机绝对路径：
`/Users/mikijin/Library/Application Support/violoop/workspace/outputs/surgo_flutter`

使用 Flutter 3.27.2 / Dart 3.6.1 验证。团队可先按 `pubspec.lock` 还原依赖，升级 SDK 后重新运行所有测试，不直接假设插件兼容。

```sh
cd "/Users/mikijin/Library/Application Support/violoop/workspace/outputs/surgo_flutter"
flutter pub get
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn
flutter run -d chrome
```

本机代理会干扰 Flutter 的 localhost 通信，验证脚本仅清除子进程的 HTTP/HTTPS/ALL_PROXY（大小写）并设置 NO_PROXY=localhost,127.0.0.1，不修改系统网络配置。可使用 `python tool/verify_handover.py` 生成验证日志。

此 SDK 不支持 `flutter build web --debug`。调试替代：
`flutter run -d web-server --debug --no-hot --web-hostname 127.0.0.1 --web-port 8947`。

Web构建输出在 `build/web/`。通过 HTTP 服务访问，不直接双击 index.html。调试/演示默认从考试选择页进入。

## 源码结构

|目录|职责|
|---|---|
|`lib/main.dart`|加载词典/题库、Provider、App入口|
|`lib/app/routes.dart`|141个源route key与ExamType/UiLang|
|`lib/app/app_state.dart`|当前页面、考试类型、语言、共享session；保留源JS变量名|
|`lib/app/shell.dart`|统一页面挂载、嵌套Navigator、手机框、滚动策略、全局按钮|
|`lib/features/`|按训练/模考/反馈模块划分的原生页面、数据适配与controller|
|`lib/theme/`|颜色/字体/尺寸；源shrinkFonts的-2px与10px下限|
|`lib/widgets/`|通用按钮/卡片、生成/批改弹窗、视频、菜单与翻译文本|
|`assets/data/`|从原JS导出的题库、固定反馈、任务描述、翻译映射|
|`assets/images,fonts,video/`|原型本地资源|
|`test/`|控制器、页面交互、跨页面流程、路由与双语审计|
|`test/fixtures/`|原JS执行/原DOM文本节点预期结果|
|`tool/`|源数据导出、校验与交接审计脚本|
|`docs/`|路由映射、验证边界、差异及交接说明|

完整逐路由映射见 `ROUTE_MAPPING.md` / `route_mapping.json`，来自实际测试挂载的Widget类，不是根据文件名猜测。

## 团队集成约定

1. 先复用完整AppState + shell确认行为；若接入现有Router，可将 `AppState.go(SurgoPage)`适配为团队路由，但必须保留source session及启动/退出计时清理。
2. 大多数页面是自然高度Column，由shell统一滚动。阅读、口语等有界页面直接由shell提供高度；不要再套无界SingleChildScrollView。Row内SurgoButton必须有限宽。
3. 改动题库前运行导出校验；当前反馈很多是**固定演示答案/分数**，不是对用户输入实时评分。不要擅改成真实判分或补官方题目。
4. 页面中的“录音”多数只有原型计时/波形；没有保存音频。TTS仅在源实际调用speechSynthesis的页面使用，其他模拟听力不额外添加音轨。
5. `T`用于按原全局字典翻译UI；`SourceText`只执行原页面真实DOM中已经发生过的逐route/lang完整文本替换，不修改TextField值。新增非默认页面状态需要补原DOM证据，而非放宽为任意翻译。
6. session是内存状态，刷新App会重建；源文案“任务已保存”等不意味着已有服务端持久化。没有用户账号认证、真实支付、远程消息推送。
7. 最初安装的一些依赖仍未使用（包括webview_flutter）；源码没有WebView实现。团队清理依赖应独立提交并重新验证移动端注册插件，不混入规则迁移。

## 验证证据

- 原数据：`tool/export_source.cjs --check`校验题库、四张翻译表及SHA256；各模块export脚本保留source常量。
- 翻译算法：2,862个原applyLang案例、102个JS正则替换案例；真实DOM补充2026条route/lang映射，完整282状态节点保存在fixture。
- 渲染：141 route原生挂载；282个route×语言初始状态无占位/布局异常。TTS通道在此审计中是测试替身，不是媒体能力证明。
- 交互：`STATE_PARITY_AUDIT.md`列出计时/重录/跨题状态/字数提示/拖拽等测试范围。
- 可见Web路径：`VISUAL_CHECK.md`记录本轮实际操作与截图证据，未生成虚假的像素相似度。
- 最终日志：`docs/verification/summary.json`以及同目录命令日志（由校验脚本产生）。

## 移动端未验证项

本次未构建、签名或运行iOS/Android真机产物；不得发布为可上架版本。须核对：SDK/Gradle/Xcode插件兼容；SafeArea与系统导航返回；小屏键盘/输入法组合输入；旋转、后台/前台计时；原生拖拽/滚动冲突；TTS语言、速率、完成/错误回调；视频播放与静音循环；离线资源加载；系统字体和无障碍语义。真实录音、远程推送、后端评分目前并未实现，不能用“未测试”暗示其已存在。
