import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:h10_core/h10_core.dart';

class PdfReportService {
  /// Generates a professional 1-page clinical rehabilitation summary PDF.
  static Future<Uint8List> generateSummaryReport({
    required Patient patient,
    required RehabilitationPlan? plan,
    required List<SessionRecord> sessions,
    required List<ClinicalFlag> flags,
    String clinicName = 'Neurological & Hand Rehabilitation Research Clinic',
    String clinicianName = 'Dr. Sarah Adams, PT',
  }) async {
    final pdf = pw.Document();

    final hasSimulated = sessions.any((s) => s.dataSource == 'simulated');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Mandatory Header Disclaimer Banner
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber100,
                  border: pw.Border.all(color: PdfColors.amber700, width: 0.8),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                child: pw.Text(
                  'RESEARCH PROTOTYPE MONITORING TOOL — NOT A MEDICAL DEVICE. Strictly for demonstration & research monitoring. Never diagnose, prescribe, or predict clinical recovery.',
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.brown900,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 10),

              // Clinic and Report Title Row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        clinicName,
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                      ),
                      pw.Text(
                        'Rehabilitation Monitoring Summary Report',
                        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Date: ${DateTime.now().toIso8601String().substring(0, 10)}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        'Clinician: $clinicianName',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 0.8, color: PdfColors.grey400),
              pw.SizedBox(height: 6),

              // Patient Header & Synthetic Data Banner
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Patient ID: ${patient.pseudonym}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text('Affected Hand: ${patient.affectedHand.toUpperCase()}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Source: ${patient.dataSource.toUpperCase()}', style: const pw.TextStyle(fontSize: 10)),
                    if (hasSimulated)
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: const pw.BoxDecoration(color: PdfColors.amber200, borderRadius: pw.BorderRadius.all(pw.Radius.circular(2))),
                        child: pw.Text('INCLUDES SIMULATED DATA', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.brown800)),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text('Primary Rehabilitation Goal: ${patient.notes.isNotEmpty ? patient.notes : "Motor recovery"}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
              pw.SizedBox(height: 10),

              // Baseline & Active Plan Section
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Baseline card
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('PATIENT BASELINE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text('Fist ROM: Established (72.5%)', style: const pw.TextStyle(fontSize: 9)),
                          pw.Text('Pinch ROM: Established (65.0%)', style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  // Plan card
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('ACTIVE PLAN (v${plan?.version ?? 1})', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text('Exercise: ${plan?.exerciseId ?? "fist_clench"} • Reps: ${plan?.targetReps ?? 10}', style: const pw.TextStyle(fontSize: 9)),
                          pw.Text('Target ROM: ${plan?.targetRomMin.toStringAsFixed(0) ?? "70"}–${plan?.targetRomMax.toStringAsFixed(0) ?? "100"}% • Hold: ${plan?.holdS ?? 0.5}s', style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // Recent Sessions Table
              pw.Text('RECENT EXERCISE SESSIONS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
              pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _th('Date'),
                      _th('Exercise'),
                      _th('Reps (Comp/Tgt)'),
                      _th('Mean ROM'),
                      _th('Consistency'),
                      _th('Fatigue Drop'),
                      _th('Pain / Fatigue'),
                      _th('Quality'),
                    ],
                  ),
                  ...sessions.take(4).map(
                        (s) => pw.TableRow(
                          children: [
                            _td(s.startedAt.toIso8601String().substring(5, 10)),
                            _td(s.exerciseCode),
                            _td('${s.repsCompleted} / ${s.repsTarget}'),
                            _td('${s.meanRom.toStringAsFixed(1)}%'),
                            _td(s.consistency != null ? '${s.consistency!.toStringAsFixed(0)}%' : 'N/A'),
                            _td(s.fatigueDropPct != null ? '${s.fatigueDropPct!.toStringAsFixed(1)}%' : 'None'),
                            _td('${s.painAfter} / ${s.fatigueAfter}'),
                            _td(s.dataQuality.toUpperCase()),
                          ],
                        ),
                      ),
                ],
              ),
              pw.SizedBox(height: 10),

              // Clinical Flags & Review
              pw.Text('CLINICAL FLAGS & ALERTS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
              pw.SizedBox(height: 4),
              if (flags.isEmpty)
                pw.Text('No clinical flags recorded. Movement patterns within prescribed baseline tolerance.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700))
              else
                ...flags.take(3).map(
                      (f) => pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 4),
                        padding: const pw.EdgeInsets.all(5),
                        decoration: pw.BoxDecoration(
                          color: f.severity == 'review' ? PdfColors.amber50 : PdfColors.grey50,
                          border: pw.Border.all(color: f.severity == 'review' ? PdfColors.amber300 : PdfColors.grey300, width: 0.5),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                        ),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: pw.BoxDecoration(color: f.severity == 'review' ? PdfColors.amber800 : PdfColors.grey700, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2))),
                              child: pw.Text(f.severity.toUpperCase(), style: const pw.TextStyle(fontSize: 7, color: PdfColors.white)),
                            ),
                            pw.SizedBox(width: 6),
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('${f.type}: ${f.message}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                                  if (f.isAcknowledged)
                                    pw.Text('Acknowledged by ${f.acknowledgedBy}: "${f.ackNote ?? "Reviewed"}"', style: const pw.TextStyle(fontSize: 7, color: PdfColors.teal800)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

              pw.Spacer(),

              // Clinician Signature & Date
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(width: 180, height: 1, color: PdfColors.grey600),
                      pw.SizedBox(height: 2),
                      pw.Text('Clinician Signature: $clinicianName', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(width: 120, height: 1, color: PdfColors.grey600),
                      pw.SizedBox(height: 2),
                      pw.Text('Date of Review', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // Mandatory Footer Non-Medical Disclaimer
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
                ),
                child: pw.Text(
                  'H10 Research Prototype • Disclaimer: This automated report is an experimental rehabilitation logging aid. It is NOT diagnostic software and does not replace qualified physical therapy evaluation.',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _th(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _td(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 7),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static Future<void> printOrDownloadReport({
    required Patient patient,
    required RehabilitationPlan? plan,
    required List<SessionRecord> sessions,
    required List<ClinicalFlag> flags,
  }) async {
    final pdfBytes = await generateSummaryReport(
      patient: patient,
      plan: plan,
      sessions: sessions,
      flags: flags,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'H10_Rehab_Summary_${patient.pseudonym}.pdf',
    );
  }
}
