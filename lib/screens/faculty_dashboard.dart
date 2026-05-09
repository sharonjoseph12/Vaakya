import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import '../core/local_db.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import 'quiz_screen.dart';

class FacultyDashboard extends StatefulWidget {
  const FacultyDashboard({super.key});
  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  List<Map<String, dynamic>> _notes = [];
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() { super.initState(); _loadNotes(); }

  Future<void> _loadNotes() async {
    final notes = await LocalDatabase.instance.getFacultyNotes();
    setState(() { _notes = notes; _loading = false; });
  }

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['txt', 'pdf', 'md']);
    if (result == null || result.files.isEmpty) return;
    setState(() => _uploading = true);

    final file = result.files.first;
    String content = '';
    String title = file.name;

    if (file.path != null) {
      try {
        content = await File(file.path!).readAsString();
      } catch (_) {
        content = 'Binary file uploaded: ${file.name} (${(file.size / 1024).toStringAsFixed(1)} KB)';
      }
    }

    await LocalDatabase.instance.addFacultyNote(title: title, content: content, filePath: file.path ?? '');
    await _loadNotes();
    setState(() => _uploading = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ "$title" uploaded!', style: GoogleFonts.outfit()), backgroundColor: const Color(0xFF6C63FF)));
  }

  Future<void> _addManualNote() async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    await showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Add Study Notes', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Chapter 5: Photosynthesis')),
        const SizedBox(height: 12),
        TextField(controller: contentCtrl, maxLines: 6, decoration: const InputDecoration(labelText: 'Content', hintText: 'Type or paste notes here...')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (titleCtrl.text.isNotEmpty && contentCtrl.text.isNotEmpty) {
              await LocalDatabase.instance.addFacultyNote(title: titleCtrl.text, content: contentCtrl.text, filePath: '');
              if (ctx.mounted) Navigator.pop(ctx);
              _loadNotes();
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtextColor = isDark ? Colors.white54 : Colors.black54;
    final cardColor = isDark ? const Color(0xFF161B22) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text('👨‍🏫 Faculty Dashboard', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(context.watch<ThemeProvider>().isDark ? Icons.light_mode : Icons.dark_mode), onPressed: () => context.read<ThemeProvider>().toggleTheme()),
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: () { context.read<ProfileProvider>().setRole(''); Navigator.pushReplacementNamed(context, '/role'); }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Upload section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF6584), Color(0xFFFF8FA3)]), borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              Row(children: [
                const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Upload Study Material', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  Text('PDF, TXT, or Markdown files', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                ])),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: ElevatedButton.icon(
                  onPressed: _uploading ? null : _uploadFile,
                  icon: _uploading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.attach_file_rounded),
                  label: Text(_uploading ? 'Uploading...' : 'Upload File'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFFFF6584), padding: const EdgeInsets.symmetric(vertical: 14)),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton.icon(
                  onPressed: _addManualNote,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Type Notes'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.2), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                )),
              ]),
            ]),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          // Quick actions
          Text('Quick Actions', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
          const SizedBox(height: 12),
          Row(children: [
            _actionCard('📝', 'Generate\nQuiz', const Color(0xFF6C63FF), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen()))),
            const SizedBox(width: 12),
            _actionCard('📊', 'View\nAnalytics', const Color(0xFF00D2FF), () => Navigator.pushNamed(context, '/dashboard')),
          ]).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 24),

          // Uploaded notes list
          Row(children: [
            Text('Uploaded Materials', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
            const Spacer(),
            Text('${_notes.length} files', style: GoogleFonts.outfit(fontSize: 13, color: subtextColor)),
          ]),
          const SizedBox(height: 12),

          if (_loading) const Center(child: CircularProgressIndicator())
          else if (_notes.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
              child: Center(child: Column(children: [
                const Text('📂', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text('No materials uploaded yet', style: GoogleFonts.outfit(color: subtextColor)),
              ])),
            )
          else
            ...List.generate(_notes.length, (i) {
              final note = _notes[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFFF6584).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.description_rounded, color: Color(0xFFFF6584), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(note['title'], style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
                    Text('${((note['content']?.toString().length ?? 0) / 100).toStringAsFixed(0)} paragraphs • ${_formatDate(note['created_at'])}', style: GoogleFonts.outfit(fontSize: 11, color: subtextColor)),
                  ])),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                    onPressed: () async { await LocalDatabase.instance.removeFacultyNote(note['id']); _loadNotes(); },
                  ),
                ]),
              ).animate().fadeIn(delay: Duration(milliseconds: 100 * i), duration: 300.ms);
            }),
        ]),
      ),
    );
  }

  Widget _actionCard(String emoji, String label, Color color, VoidCallback onTap) {
    return Expanded(child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.3))),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ]),
        ),
      ),
    ));
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    return d != null ? '${d.day}/${d.month}' : '';
  }
}
