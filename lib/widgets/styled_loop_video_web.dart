import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// A media-only platform view. All surrounding screens remain Dart Widgets.
/// CSS effects must be on the video element; CanvasKit cannot filter it.
class StyledLoopVideo extends StatefulWidget {
  const StyledLoopVideo(
      {super.key,
      required this.asset,
      required this.width,
      required this.height,
      this.brightness = 1,
      this.radius = 0});
  final String asset;
  final double width, height, brightness, radius;
  @override
  State<StyledLoopVideo> createState() => _StyledLoopVideoState();
}

class _StyledLoopVideoState extends State<StyledLoopVideo> {
  web.HTMLVideoElement? video;
  JSFunction? errorListener;
  bool failed = false;
  void created(Object element) {
    final v = element as web.HTMLVideoElement;
    video = v;
    v.muted = true;
    v.loop = true;
    v.autoplay = true;
    v.preload = 'auto';
    v.setAttribute('playsinline', '');
    v.setAttribute('disablepictureinpicture', '');
    v.style.width = '100%';
    v.style.height = '100%';
    v.style.objectFit = 'contain';
    v.style.border = 'none';
    v.style.display = 'block';
    applyStyle();
    errorListener = ((web.Event event) {
      if (mounted) setState(() => failed = true);
    }).toJS;
    v.addEventListener('error', errorListener);
    v.src = ui_web.assetManager.getAssetUrl(widget.asset);
    v.play().toDart.then((_) {}, onError: (Object e) {
      if (mounted) setState(() => failed = true);
    });
  }

  void applyStyle() {
    video?.style.filter = 'brightness(${widget.brightness})';
    video?.style.borderRadius = '${widget.radius}px';
  }

  @override
  void didUpdateWidget(covariant StyledLoopVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    applyStyle();
    if (oldWidget.asset != widget.asset) {
      failed = false;
      video?.src = ui_web.assetManager.getAssetUrl(widget.asset);
    }
  }

  @override
  void dispose() {
    final v = video;
    if (v != null) {
      v.pause();
      if (errorListener != null) v.removeEventListener('error', errorListener);
      v.removeAttribute('src');
      v.load();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
      width: widget.width,
      height: widget.height,
      child: failed
          ? const Center(child: Text('视频暂不可用', style: TextStyle(fontSize: 10)))
          : HtmlElementView.fromTagName(
              tagName: 'video', onElementCreated: created));
}
