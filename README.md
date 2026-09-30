# surgo_flutter

## Vercel 演示（`vercel` 分支）

线上：https://demo.surgo.cc （同一份构建也在 https://surgo-demo.vercel.app ）。页面只读打包进去的 JSON、
题图和音频，不调接口，也不现场生成内容。

- **构建**：`vercel.json` → `tool/vercel_build.sh --demo-data`。固定 Flutter 3.44.4；兜底字体（中文、符号、emoji）
  构建时拷进站点自己的 `fonts/`，不请求 Google；`demo_data/` 盖到 `assets/data/` 上再构建。
- **数据**：`demo_data/` 是从本地后端库只读导出的一位学员的真实作答，`assets/data/` 仍是原型数据（测试跑的是它）。
  怎么导、哪些规矩、怎么验证见 `tool/demo_export/README.md`；换一场作答 = 改对应模块文件头的 id，
  重跑 `node tool/demo_export/export.cjs`，提交 `demo_data/`。
- **声音**：原型里听力、考官提问、回放都是计时器模拟，包里没有音频。演示包带上了后端存着的真音频
  （`demo_data/aud_*.mp3`），页面经 `lib/widgets/demo_audio.dart` 播放；录音（麦克风）仍是模拟的。
  手机上音频要由一次点击解锁、读不出声时怎么兜底，都写在 `demo_audio_web.dart` 和导出目录的 README 里。
- **发布**：推 `vercel` 分支。Vercel 项目 `surgo-demo` 已连这个 GitHub 仓库，生产分支是 `vercel`，推送后自动
  构建并上线；其他分支不构建（项目的 Ignored Build Step）。要手动发时：本地跑构建脚本，再
  `vercel deploy --prebuilt --prod`（产物放 `.vercel/output/static`）。

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
