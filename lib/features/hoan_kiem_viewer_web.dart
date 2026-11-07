import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

class HoanKiemViewer extends StatelessWidget {
  const HoanKiemViewer({super.key, required this.url});

  final Uri url;

  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(
    tagName: 'iframe',
    onElementCreated: (element) {
      final frame = element as web.HTMLIFrameElement;
      frame
        ..title = 'Hoan Kiem Lake VR360 by Báo Nhân Dân'
        ..setAttribute(
          'sandbox',
          'allow-scripts allow-same-origin allow-popups',
        )
        ..allowFullscreen = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = '0'
        ..src = url.toString();
    },
  );
}
