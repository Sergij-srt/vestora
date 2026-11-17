void triggerFileDownload(String filename, String content) {
  // No-op on VM / native platforms
}

void triggerBinaryDownload(String filename, String base64Data, String mimeType) {
  // No-op on VM / native platforms
}

Future<String?> compressImageDataUri(
  String dataUri, {
  int maxDimension = 1024,
  int maxDataUriChars = 360000,
}) async {
  return null;
}

Future<String> requestNotificationPermission() async {
  return 'unsupported';
}

void sendWebNotification(String title, {String? body, String? icon}) {
  // No-op on VM / native platforms
}
