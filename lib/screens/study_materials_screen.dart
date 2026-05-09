import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/local_db.dart';

class StudyMaterialsScreen extends StatefulWidget {
  const StudyMaterialsScreen({super.key});
  @override
  State<StudyMaterialsScreen> createState() => _StudyMaterialsScreenState();
}

class _StudyMaterialsScreenState extends State<StudyMaterialsScreen> {
  List<Map<String, dynamic>> _notes = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final notes = await LocalDatabase.instance.getFacultyNotes();
    setState(() { _notes = notes; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('📖 Study Materials', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('📂', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text('No study materials yet', style: GoogleFonts.outfit(fontSize: 18, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Text('Your teacher hasn\'t uploaded any notes yet.', style: GoogleFonts.outfit(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notes.length,
                  itemBuilder: (context, i) {
                    final note = _notes[i];
                    return GestureDetector(
                      onTap: () => _showNote(note),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF161B22) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFF6C63FF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.menu_book_rounded, color: Color(0xFF6C63FF), size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(note['title'] ?? 'Notes', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text('${(note['content']?.toString().split(' ').length ?? 0)} words', style: GoogleFonts.outfit(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                          ])),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        ]),
                      ),
                    ).animate().fadeIn(delay: Duration(milliseconds: 60 * i), duration: 300.ms);
                  },
                ),
    );
  }

  void _showNote(Map<String, dynamic> note) {
    final theme = Theme.of(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      appBar: AppBar(title: Text(note['title'] ?? 'Notes', style: GoogleFonts.outfit(fontWeight: FontWeight.w700))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SelectableText(note['content'] ?? '', style: GoogleFonts.outfit(fontSize: 15, height: 1.7, color: theme.colorScheme.onSurface)),
      ),
    )));
  }
}
