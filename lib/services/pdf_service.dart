import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/user_model.dart';
import '../models/grade_model.dart';
import '../models/krs_model.dart';

class PdfService {
  // ─── KHS PDF ──────────────────────────────────────────
  static Future<void> generateKHS({
    required UserModel user,
    required List<GradeModel> grades,
    required String semester,
  }) async {
    final pdf = pw.Document();

    // Hitung IP
    int totalSks = 0;
    double totalBobot = 0;
    for (final g in grades) {
      totalSks += g.sks;
      totalBobot += g.bobotNilai;
    }
    final ip = totalSks > 0 ? totalBobot / totalSks : 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue900,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'KARTU HASIL STUDI (KHS)',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Sistem Informasi Akademik Mahasiswa',
                  style: const pw.TextStyle(
                    color: PdfColors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Info Mahasiswa
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              children: [
                _infoRow('Nama', user.nama),
                _infoRow('NIM', user.nim),
                _infoRow('Program Studi', user.prodi),
                _infoRow('Angkatan', user.angkatan),
                _infoRow('Semester', semester),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Tabel Nilai
          pw.Text(
            'Daftar Nilai',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
            },
            children: [
              // Header tabel
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                children: ['Kode', 'Mata Kuliah', 'SKS', 'Nilai', 'Grade']
                    .map(
                      (h) => pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          h,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    )
                    .toList(),
              ),
              // Data
              ...grades.map(
                (g) => pw.TableRow(
                  children:
                      [
                            g.kode,
                            g.matkul,
                            '${g.sks}',
                            '${g.nilai.toStringAsFixed(0)}',
                            g.grade,
                          ]
                          .map(
                            (v) => pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(v),
                            ),
                          )
                          .toList(),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: const pw.BoxDecoration(color: PdfColors.blue50),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _summaryBox('Total SKS', '$totalSks'),
                _summaryBox('IP Semester', ip.toStringAsFixed(2)),
              ],
            ),
          ),

          pw.SizedBox(height: 32),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('Mengetahui,'),
                  pw.SizedBox(height: 48),
                  pw.Text('Dosen Wali'),
                  pw.Divider(),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // ─── KRS PDF ──────────────────────────────────────────
  static Future<void> generateKRS({
    required UserModel user,
    required List<KrsModel> krsList,
    required String semester,
  }) async {
    final pdf = pw.Document();
    final totalSks = krsList.fold(0, (sum, k) => sum + k.sks);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              color: PdfColors.green800,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'KARTU RENCANA STUDI (KRS)',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Semester $semester',
                    style: const pw.TextStyle(color: PdfColors.white70),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Nama: ${user.nama}'),
            pw.Text('NIM: ${user.nim}'),
            pw.Text('Prodi: ${user.prodi}'),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.green100),
                  children: ['No', 'Kode', 'Mata Kuliah', 'SKS', 'Status']
                      .map(
                        (h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            h,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      )
                      .toList(),
                ),
                ...krsList.asMap().entries.map(
                  (e) => pw.TableRow(
                    children:
                        [
                              '${e.key + 1}',
                              e.value.kode,
                              e.value.namaMatkul,
                              '${e.value.sks}',
                              e.value.status,
                            ]
                            .map(
                              (v) => pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(v),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Total SKS: $totalSks',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(': $value'),
        ],
      ),
    );
  }

  static pw.Widget _summaryBox(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
      ],
    );
  }
}
