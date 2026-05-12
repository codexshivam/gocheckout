import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'file_downloader.dart';

enum ExportFormat { csv, excel, pdf }

extension ExportFormatX on ExportFormat {
  String get label {
    switch (this) {
      case ExportFormat.csv:
        return 'CSV';
      case ExportFormat.excel:
        return 'Excel';
      case ExportFormat.pdf:
        return 'PDF';
    }
  }
}

Future<bool> exportTabularData({
  required String baseFileName,
  required List<String> headers,
  required List<List<String>> rows,
  required ExportFormat format,
}) async {
  switch (format) {
    case ExportFormat.csv:
      return _exportCsv(baseFileName, headers, rows);
    case ExportFormat.excel:
      return _exportExcel(baseFileName, headers, rows);
    case ExportFormat.pdf:
      return _exportPdf(baseFileName, headers, rows);
  }
}

Future<bool> _exportCsv(
  String baseFileName,
  List<String> headers,
  List<List<String>> rows,
) async {
  final StringBuffer buffer = StringBuffer();
  buffer.writeln(headers.map(_csvEscape).join(','));
  for (final row in rows) {
    buffer.writeln(row.map(_csvEscape).join(','));
  }

  final Uint8List bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
  return downloadBytesFile(
    filename: '$baseFileName.csv',
    bytes: bytes,
    mimeType: 'text/csv;charset=utf-8',
  );
}

Future<bool> _exportExcel(
  String baseFileName,
  List<String> headers,
  List<List<String>> rows,
) async {
  final StringBuffer buffer = StringBuffer();
  buffer.writeln(headers.map(_tsvEscape).join('\t'));
  for (final row in rows) {
    buffer.writeln(row.map(_tsvEscape).join('\t'));
  }

  final Uint8List bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
  return downloadBytesFile(
    filename: '$baseFileName.xls',
    bytes: bytes,
    mimeType: 'application/vnd.ms-excel',
  );
}

Future<bool> _exportPdf(
  String baseFileName,
  List<String> headers,
  List<List<String>> rows,
) async {
  final pw.Document pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (pw.Context context) {
        return [
          pw.Text(
            baseFileName,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey600),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ];
      },
    ),
  );

  final Uint8List bytes = await pdf.save();
  return downloadBytesFile(
    filename: '$baseFileName.pdf',
    bytes: bytes,
    mimeType: 'application/pdf',
  );
}

String _csvEscape(String value) {
  final String escaped = value.replaceAll('"', '""');
  return '"$escaped"';
}

String _tsvEscape(String value) {
  return value.replaceAll('\t', ' ').replaceAll('\n', ' ');
}
