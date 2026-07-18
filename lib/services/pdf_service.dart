// PdfService
// Tạo file PDF từ danh sách publication

import 'dart:io';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import '../models/publication.dart';
import '../models/openalex_ranked_entity.dart';

class PdfService {
  static Future<File> generateReport({
    required String topic,
    required List<Publication> papers,
    required List<OpenAlexRankedEntity> journals,
    required List<OpenAlexRankedEntity> authors,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
          build: (context) => [

            pw.Header(
              level: 0,
              child: pw.Text('Research Report'),
            ),

            pw.Text('Topic: $topic'),

            pw.SizedBox(height: 20),

            pw.Text(
              'Top Journals',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            ...journals.take(5).toList().asMap().entries.map(
                  (entry) => pw.Bullet(
                text:
                '${entry.key + 1}. ${entry.value.name} - ${entry.value.count} publications',
              ),
            ),

            pw.SizedBox(height: 20),

            pw.Text(
              'Top Authors',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            ...authors.take(5).toList().asMap().entries.map(
                  (entry) => pw.Bullet(
                text:
                '${entry.key + 1}. ${entry.value.name} - ${entry.value.count} publications',
              ),
            ),

            pw.SizedBox(height: 20),

            pw.Text(
              'Top Papers',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            ...papers.take(20).map(
                  (paper) => pw.Bullet(
                text:
                '${paper.title} (${paper.year}) - ${paper.citations} citations',
              ),
            ),
          ]
      ),
    );

    final directory =
    await getTemporaryDirectory();

  final file = File(
    '${directory.path}/research_report.pdf',
  );

  await file.writeAsBytes(
  await pdf.save(),
  );

  return file;
}

  static Future<Uint8List> generateReportBytes({
    required String topic,
    required List<Publication> papers,
    required List<OpenAlexRankedEntity> journals,
    required List<OpenAlexRankedEntity> authors,
    required int totalPublications,
  }) async {
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: font,
        bold: fontBold,
      ),
    );
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [

          // TITLE
          pw.Center(
            child: pw.Text(
              'RESEARCH REPORT',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),

          pw.SizedBox(height: 10),

          // TOPIC
          pw.Text(
            'Topic: $topic',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.Text(
            'Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
          ),

          pw.SizedBox(height: 20),

          // SUMMARY BOX
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
            ),
            child: pw.Column(
              crossAxisAlignment:
              pw.CrossAxisAlignment.start,
              children: [

                pw.Text(
                  'Summary',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 5),

                pw.Text(
                  'Total Papers: $totalPublications',
                ),

                pw.Text(
                  'Top Journals: ${journals.length}',
                ),

                pw.Text(
                  'Top Authors: ${authors.length}',
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // TOP JOURNALS
          pw.Text(
            'Top Journals',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 10),

          pw.TableHelper.fromTextArray(
            headers: [
              '#',
              'Journal',
              'Publications',
            ],
            data: journals
                .take(5)
                .toList()
                .asMap()
                .entries
                .map(
                  (e) => [
                '${e.key + 1}',
                e.value.name,
                e.value.count.toString(),
              ],
            )
                .toList(),
          ),

          pw.SizedBox(height: 20),

          // TOP AUTHORS
          pw.Text(
            'Top Authors',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 10),

          pw.TableHelper.fromTextArray(
            headers: [
              '#',
              'Author',
              'Publications',
            ],
            data: authors
                .take(5)
                .toList()
                .asMap()
                .entries
                .map(
                  (e) => [
                '${e.key + 1}',
                e.value.name,
                e.value.count.toString(),
              ],
            )
                .toList(),
          ),

          pw.SizedBox(height: 20),

          // TOP PAPERS
          pw.Text(
            'Top Papers',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 10),

          ...papers.take(10).map(
                (paper) => pw.Bullet(
              text:
              '${paper.title} (${paper.year}) - ${paper.citations} citations',
            ),
          ),

          pw.SizedBox(height: 30),

          pw.Divider(),

          pw.Center(
            child: pw.Text(
              'Generated by JournalAI',
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

}