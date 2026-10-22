import 'dart:js_interop' as js;

@js.JS('vestoraTriggerPwaInstall')
external void _vestoraTriggerPwaInstall();

void triggerPwaInstall() {
  try {
    _vestoraTriggerPwaInstall();
  } catch (_) {}
}
