void triggerFileDownload(String filename, String content) {
  // No-op on VM / native platforms
}

Future<String> requestNotificationPermission() async {
  return 'unsupported';
}

void sendWebNotification(String title, {String? body, String? icon}) {
  // No-op on VM / native platforms
}
