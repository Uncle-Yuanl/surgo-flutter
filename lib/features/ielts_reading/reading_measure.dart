import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Reports natural question height without constraining the scrollable content.
class ReadingMeasure extends SingleChildRenderObjectWidget {
  const ReadingMeasure({super.key, required this.onSize, required super.child});
  final ValueChanged<Size> onSize;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _ReadingMeasure(onSize);
  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _ReadingMeasure).onSize = onSize;
  }
}

class _ReadingMeasure extends RenderProxyBox {
  _ReadingMeasure(this.onSize);
  ValueChanged<Size> onSize;
  Size? previous;
  @override
  void performLayout() {
    super.performLayout();
    if (previous == size) return;
    previous = size;
    final measured = size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) onSize(measured);
    });
  }
}
