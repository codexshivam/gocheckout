import 'package:universal_html/html.dart' as html;

Future<bool> downloadCsvFile({
  required String filename,
  required String csvContent,
}) async {
  final html.Blob blob = html.Blob(<String>[csvContent], 'text/csv;charset=utf-8');
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
