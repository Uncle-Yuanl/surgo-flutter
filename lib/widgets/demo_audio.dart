// 演示用的真实音频（tool/demo_export 导出的 assets/data/aud_*.mp3，见那里的 README「音频」）。
// 网页上全站共用一个 <audio>；原生端和测试里不出声（available 为 false），页面照旧走原型的计时模拟。
export 'demo_audio_native.dart'
    if (dart.library.js_interop) 'demo_audio_web.dart';
