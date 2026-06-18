import 'dart:html' as html;

bool get preferLightMedia {
  try {
    return html.window.innerWidth != null && html.window.innerWidth! < 900;
  } catch (_) {
    return true;
  }
}
