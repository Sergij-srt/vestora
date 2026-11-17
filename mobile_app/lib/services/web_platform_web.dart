import 'dart:js_interop' as js;

@js.JS('vestoraDownloadFile')
external void _vestoraDownloadFile(js.JSString filename, js.JSString content);

@js.JS('vestoraDownloadBinary')
external void _vestoraDownloadBinary(js.JSString filename, js.JSString base64Data, js.JSString mimeType);

@js.JS('vestoraCompressImage')
external js.JSPromise<js.JSString> _vestoraCompressImage(
  js.JSString dataUrl,
  js.JSNumber maxDim,
  js.JSNumber maxChars,
);

@js.JS('vestoraRequestNotificationPermission')
external js.JSPromise<js.JSString> _vestoraRequestNotificationPermission();

@js.JS('vestoraSendNotification')
external void _vestoraSendNotification(js.JSString title, js.JSString? body, js.JSString? icon);

void triggerFileDownload(String filename, String content) {
  try {
    _vestoraDownloadFile(filename.toJS, content.toJS);
  } catch (_) {}
}

void triggerBinaryDownload(String filename, String base64Data, String mimeType) {
  try {
    _vestoraDownloadBinary(filename.toJS, base64Data.toJS, mimeType.toJS);
  } catch (_) {}
}

Future<String?> compressImageDataUri(
  String dataUri, {
  int maxDimension = 1024,
  int maxDataUriChars = 360000,
}) async {
  try {
    final promise = _vestoraCompressImage(
      dataUri.toJS,
      maxDimension.toJS,
      maxDataUriChars.toJS,
    );
    final result = (await promise.toDart).toDart;
    return result.isNotEmpty ? result : null;
  } catch (_) {
    return null;
  }
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
