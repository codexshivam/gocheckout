import 'dart:typed_data';

import 'package:universal_html/html.dart' as html;

Future<bool> downloadBytesFile({
  required String filename,
  required Uint8List bytes,
  required String mimeType,
}) async {
  final html.Blob blob = html.Blob(<dynamic>[bytes], mimeType);
  final String url = html.Url.createObjectUrlFromBlob(blob);

  final html.AnchorElement anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  html.Url.revokeObjectUrl(url);
  return true;
}
