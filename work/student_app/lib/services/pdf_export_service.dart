import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfExportService {
  static Future<Uint8List> generateCourseCheatSheet({
    required String courseTitle,
    required int semester,
    required List<Map<String, dynamic>> lessons,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'NURSEPATH PAKISTAN — CLINICAL ROTATION CHEAT SHEET',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '$courseTitle (Semester $semester)',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    'HEC Generic BSN 2024',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            ...lessons.map((lesson) {
              final title = lesson['title'] ?? 'Lesson';
              final keyTerms = (lesson['keyTerms'] as List?)?.cast<Map<String, String>>() ?? [];
              final cautions = (lesson['cautions'] as List?)?.cast<String>() ?? [];

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 16),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal900,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    if (keyTerms.isNotEmpty) ...[
                      pw.Text(
                        'Key Clinical Terms:',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      ...keyTerms.map(
                        (term) => pw.Bullet(
                          text: '${term['term'] ?? ''}: ${term['definition'] ?? ''}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                    ],
                    if (cautions.isNotEmpty) ...[
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        color: PdfColors.amber100,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: cautions
                              .map(
                                (c) => pw.Text(
                                  '⚠️ Patient Safety Caution: $c',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.deepOrange900,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            pw.Footer(
              trailing: pw.Text(
                'NursePath Pakistan — Offline Clinical Reference',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
