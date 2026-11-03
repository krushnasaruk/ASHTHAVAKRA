// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';

final Set<String> _registeredViewTypes = <String>{};
html.IFrameElement? _webIframe;

Widget buildPlatformHandView({
  required String viewType,
  required String assetUrl,
}) {
  if (!_registeredViewTypes.contains(viewType)) {
    _registeredViewTypes.add(viewType);
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = assetUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.backgroundColor = '#0a0a0a';
        _webIframe = iframe;
        return iframe;
      },
    );
  }
  return HtmlElementView(viewType: viewType);
}

void postPlatformMessage(String message) {
  try {
    if (_webIframe != null && _webIframe!.contentWindow != null) {
      _webIframe!.contentWindow!.postMessage(message, '*');
    }
  } catch (_) {}
}

