import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/local_db.dart';
import '../core/pdf_generator.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Map<String, dynamic>> _notes = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final notes = await LocalDatabase.instance.getBookmarks();
    setState(() { _notes = notes; _loading = false; });
  }

  Future<void> _exportPdf() async {
    if (_notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No notes to export!')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('📄 Generating PDF...', style: GoogleFonts.outfit()), backgroundColor: const Color(0xFF6C63FF)));
    await PdfGenerator.generateAndShareNotes(notes: _notes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('📝 Saved Notes', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          if (_notes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFFF6584)),
              tooltip: 'Export as PDF',
              onPressed: _exportPdf,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('📌', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text('No saved notes yet', style: GoogleFonts.outfit(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Long-press any AI answer to save it!', style: GoogleFonts.outfit(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                ]))
              : Column(children: [
                  // Export banner
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF8B7CFF)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: InkWell(
                      onTap: _exportPdf,
                      child: Row(children: [
                        const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Export as PDF', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                          Text('${_notes.length} notes ready', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                        ])),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                      ]),
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notes.length,
                      itemBuilder: (context, i) {
                        final note = _notes[i];
                        return Dismissible(
                          key: Key('${note['id']}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.delete_rounded, color: Colors.red),
                          ),
                          onDismissed: (_) async { await LocalDatabase.instance.removeBookmark(note['id'] as int); _load(); },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  const Icon(Icons.bookmark_rounded, color: Color(0xFFFFD700), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(note['topic']?.toString().isNotEmpty == true ? note['topic'] : 'Note', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13))),
                                  Text(_formatDate(note['created_at']), style: GoogleFonts.outfit(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                    onPressed: () async {
                                      await LocalDatabase.instance.removeBookmark(note['id'] as int);
                                      _load();
                                    },
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.only(left: 8),
                                  ),
                                ]),
                              const SizedBox(height: 10),
                              Text(note['text'], style: GoogleFonts.outfit(fontSize: 14, height: 1.5)),
                            ]),
                          ),
                        ).animate().fadeIn(delay: Duration(milliseconds: 50 * i), duration: 300.ms);
                      },
                    ),
                  ),
                ]),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    return '${d.day}/${d.month} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }
}
