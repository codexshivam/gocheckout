import 'dart:typed_data';

import 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart' as downloader;

Future<bool> downloadBytesFile({
  required String filename,
  required Uint8List bytes,
  required String mimeType,
}) {
  return downloader.downloadBytesFile(
    filename: filename,
    bytes: bytes,
    mimeType: mimeType,
  );
}
