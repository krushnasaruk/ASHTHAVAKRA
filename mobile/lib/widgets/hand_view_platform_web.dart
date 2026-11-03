// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';

final Set<String> _registeredViewTypes = <String>{};
final Map<String, html.IFrameElement> _webIframes = {};

Widget buildPlatformHandView({
  required String viewType,
  required String assetUrl,
}) {
  if (!_registeredViewTypes.contains(viewType)) {
    _registeredViewTypes.add(viewType);
    try {
      ui_web.platformViewRegistry.registerViewFactory(
        viewType,
        (int viewId) {
          final iframe = html.IFrameElement()
            ..src = assetUrl
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.backgroundColor = '#000000';
          _webIframes[viewType] = iframe;
          return iframe;
        },
      );
    } catch (_) {}
  }
  return HtmlElementView(viewType: viewType);
}

void postPlatformMessage(String message, [String? viewType]) {
  try {
    if (viewType != null && _webIframes.containsKey(viewType)) {
      _webIframes[viewType]?.contentWindow?.postMessage(message, '*');
    } else {
      for (final iframe in _webIframes.values) {
        iframe.contentWindow?.postMessage(message, '*');
      }
    }
  } catch (_) {}
}
