import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/widgets.dart';

class HoanKiemViewer extends StatefulWidget {
  const HoanKiemViewer({super.key, required this.url});

  final Uri url;

  @override
  State<HoanKiemViewer> createState() => _HoanKiemViewerState();
}

class _HoanKiemViewerState extends State<HoanKiemViewer> {
  WebViewController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (WebViewPlatform.instance != null) _load();
  }

  Future<void> _load() async {
    try {
      final controller = _controller ??= WebViewController();
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) async {
            final target = Uri.tryParse(request.url);
            final sameTour =
                target != null &&
                target.scheme == widget.url.scheme &&
                target.host == widget.url.host &&
                target.port == widget.url.port &&
                target.path == widget.url.path;
            if (!request.isMainFrame || sameTour) {
              return NavigationDecision.navigate;
            }
            if (target != null &&
                target.scheme == 'https' &&
                target.host == 'ltq11-ta.github.io' &&
                target.port == 443) {
              try {
                if (await launchUrl(
                  target,
                  mode: LaunchMode.externalApplication,
                )) {
                  return NavigationDecision.prevent;
                }
              } catch (_) {
                // Show the same feedback when Android has no browser handler.
              }
              if (mounted) showMessage(context, 'Could not open this link.');
            }
            return NavigationDecision.prevent;
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() => _failed = true);
            }
          },
        ),
      );
      if (!mounted) return;
      await controller.loadRequest(widget.url);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Center(
        child: FilledButton.tonal(
          onPressed: () {
            setState(() => _failed = false);
            _load();
          },
          child: const Text('Tour unavailable. Retry'),
        ),
      );
    }
    final controller = _controller;
    if (controller == null) {
      return const Center(
        child: Text('Open the original tour in your browser.'),
      );
    }
    return WebViewWidget(controller: controller);
  }
}
