import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PdfGenerator {
  /// Strip emoji and special chars that default PDF fonts can't render
  static String _clean(String text) {
    return text.replaceAll(RegExp(r'[^\x00-\x7F\u00C0-\u024F\u0900-\u097F\u2000-\u206F\u2190-\u21FF\u2200-\u22FF\u2500-\u257F°±²³√×÷→←↑↓≈≤≥≠∞θ₂₆]'), ' ').replaceAll(RegExp(r'  +'), ' ').trim();
  }

  static Future<void> generateAndShareNotes({
    required List<Map<String, dynamic>> notes,
    String title = 'Vaakya Study Notes',
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = '${now.day}-${now.month}-${now.year}';

    // Title page
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text('VAAKYA', style: pw.TextStyle(fontSize: 40, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#6C63FF'))),
          pw.SizedBox(height: 8),
          pw.Text('Study Notes', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          pw.Text('Your AI Study Companion', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
          pw.SizedBox(height: 8),
          pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
          pw.Text('Total Notes: ${notes.length}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
          pw.SizedBox(height: 30),
          pw.Container(height: 2, color: PdfColor.fromHex('#6C63FF')),
        ],
      ),
    ));

    // Content — use MultiPage so notes can span pages naturally
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      header: (ctx) => pw.Row(children: [
        pw.Text('Vaakya Study Notes', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#6C63FF'))),
        pw.Spacer(),
        pw.Text('Page ${ctx.pageNumber}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
      ]),
      build: (ctx) {
        final widgets = <pw.Widget>[];
        for (int i = 0; i < notes.length; i++) {
          final note = notes[i];
          final text = _clean(note['text']?.toString() ?? '');
          final topic = note['topic']?.toString() ?? 'Study Note';
          final date = note['created_at']?.toString() ?? '';

          widgets.add(pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 16),
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#CCCCCC')),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Row(children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#6C63FF'), borderRadius: pw.BorderRadius.circular(10)),
                  child: pw.Text('Note ${i + 1}', style: pw.TextStyle(fontSize: 9, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(child: pw.Text(topic, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
                if (date.isNotEmpty) pw.Text(_formatDate(date), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ]),
              pw.SizedBox(height: 8),
              pw.Container(height: 0.5, color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              ..._buildParagraphs(text),
            ]),
          ));
        }
        return widgets;
      },
    ));

    // Save and share
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/vaakya_notes_$dateStr.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'My Vaakya Study Notes');
  }

  static Future<void> generateChatPdf({
    required List<Map<String, String>> messages,
    String studentName = 'Student',
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = '${now.day}-${now.month}-${now.year}';

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      header: (ctx) => pw.Row(children: [
        pw.Text('Vaakya Chat Notes - $studentName', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#6C63FF'))),
        pw.Spacer(),
        pw.Text('$dateStr  |  Page ${ctx.pageNumber}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
      ]),
      build: (ctx) => messages.map((msg) {
        final isUser = msg['role'] == 'user';
        final cleanText = _clean(msg['text'] ?? '');
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 10),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: isUser ? PdfColor.fromHex('#F0EDFF') : PdfColor.fromHex('#F5F5F5'),
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: isUser ? PdfColor.fromHex('#6C63FF') : PdfColors.grey400, width: 0.5),
          ),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(isUser ? '[$studentName]' : '[Vaakya AI]', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: isUser ? PdfColor.fromHex('#6C63FF') : PdfColors.grey800)),
            pw.SizedBox(height: 4),
            ..._buildParagraphs(cleanText),
          ]),
        );
      }).toList(),
    ));

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/vaakya_chat_$dateStr.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'My Vaakya Chat Notes');
  }

  static List<pw.Widget> _buildParagraphs(String text) {
    final lines = text.split('\n');
    return lines.where((l) => l.trim().isNotEmpty).map((line) {
      final trimmed = line.trim();
      // Section headers (all caps or starts with special markers)
      if (trimmed == trimmed.toUpperCase() && trimmed.length > 3 && trimmed.length < 60) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(top: 6, bottom: 4),
          child: pw.Text(trimmed, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#6C63FF'))),
        );
      }
      // Bullet points
      if (trimmed.startsWith('*') || trimmed.startsWith('-')) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(left: 12, bottom: 2),
          child: pw.Text(trimmed, style: const pw.TextStyle(fontSize: 10)),
        );
      }
      // Hint/tip lines
      if (trimmed.contains('Hint:') || trimmed.contains('Tip:') || trimmed.contains('Memory')) {
        return pw.Container(
          margin: const pw.EdgeInsets.symmetric(vertical: 4),
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#FFF8E1'), borderRadius: pw.BorderRadius.circular(4)),
          child: pw.Text(trimmed, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#F57F17'))),
        );
      }
      return pw.Padding(padding: const pw.EdgeInsets.only(bottom: 2), child: pw.Text(trimmed, style: const pw.TextStyle(fontSize: 10)));
    }).toList();
  }

  static String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }
}
