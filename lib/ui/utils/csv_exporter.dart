import 'csv_exporter_stub.dart'
    if (dart.library.html) 'csv_exporter_web.dart' as exporter;

Future<bool> downloadCsvFile({
  required String filename,
  required String csvContent,
}) {
  return exporter.downloadCsvFile(filename: filename, csvContent: csvContent);
}
