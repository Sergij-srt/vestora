import 'dart:js_interop' as js;

@js.JS('vestoraDownloadFile')
external void _vestoraDownloadFile(js.JSString filename, js.JSString content);

@js.JS('vestoraRequestNotificationPermission')
external js.JSPromise<js.JSString> _vestoraRequestNotificationPermission();

@js.JS('vestoraSendNotification')
external void _vestoraSendNotification(js.JSString title, js.JSString? body, js.JSString? icon);

void triggerFileDownload(String filename, String content) {
  try {
    _vestoraDownloadFile(filename.toJS, content.toJS);
  } catch (_) {}
}

Future<String> requestNotificationPermission() async {
  try {
    final promise = _vestoraRequestNotificationPermission();
    final result = await promise.toDart;
    return result.toDart;
  } catch (_) {
    return 'denied';
  }
}

void sendWebNotification(String title, {String? body, String? icon}) {
  try {
    _vestoraSendNotification(
      title.toJS,
      body?.toJS,
      icon?.toJS,
    );
  } catch (_) {}
}
