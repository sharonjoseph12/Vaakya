import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/profile_provider.dart';
import '../providers/chat_provider.dart';
import '../core/api_client.dart';
import '../core/supabase_config.dart';
import '../core/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _whatsappController;
  String _selectedClass = 'Class 8';
  String _selectedBoard = 'CBSE';

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>();
    _nameController = TextEditingController(text: profile.childName);
    _whatsappController = TextEditingController();
    _selectedClass = 'Class ${profile.grade}';
    _selectedBoard = profile.board;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();

    return Scaffold(
      backgroundColor: VoiceGuruTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            // ── Avatar & Name ────────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: VoiceGuruTheme.primaryPurple,
                    child: Text(profile.childName.isNotEmpty ? profile.childName[0].toUpperCase() : 'S', style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  Text(profile.childName, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeaderBadge('Class ${profile.grade}'),
                      const SizedBox(width: 8),
                      _buildHeaderBadge(profile.board),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Form ─────────────────────────────────────────────────────────
            _buildSection(
              children: [
                _buildFieldLabel('Your Name'),
                TextField(
                  controller: _nameController,
                  decoration: _inputDecoration('Enter name'),
                ),
                const SizedBox(height: 20),
                _buildFieldLabel('Your Class'),
                DropdownButtonFormField<String>(
                  value: _selectedClass,
                  decoration: _inputDecoration(''),
                  items: List.generate(5, (i) => 'Class ${i + 6}').map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                  onChanged: (val) => setState(() => _selectedClass = val!),
                ),
                const SizedBox(height: 20),
                _buildFieldLabel('Your Board'),
                Row(
                  children: [
                    _buildBoardChip('Karnataka State Board', _selectedBoard == 'Karnataka State Board'),
                    const SizedBox(width: 8),
                    _buildBoardChip('CBSE', _selectedBoard == 'CBSE'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildBoardChip('ICSE', _selectedBoard == 'ICSE'),
                    const SizedBox(width: 8),
                    _buildBoardChip('Other', _selectedBoard == 'Other'),
                  ],
                ),
              ],
            ),

            // ── Parent Updates ──────────────────────────────────────────────
            const SizedBox(height: 24),
            _buildParentUpdatesCard(),

            // ── Actions ──────────────────────────────────────────────────────
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, 
              child: ElevatedButton.icon(
                onPressed: () {}, 
                icon: const Icon(Icons.grid_view_rounded), 
                label: const Text('Share with Teacher / Parent'), 
                style: ElevatedButton.styleFrom(backgroundColor: VoiceGuruTheme.successGreen, foregroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, 
              child: ElevatedButton(
                onPressed: () async {
                  final gradeNum = _selectedClass.split(' ').last;
                  await profile.updateProfile(
                    name: _nameController.text,
                    grade: gradeNum,
                    board: _selectedBoard,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
                  }
                }, 
                child: const Text('Save Changes'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, 
              child: OutlinedButton(
                onPressed: () {
                  context.read<ChatProvider>().clearChat();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat history cleared!')));
                }, 
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: VoiceGuruTheme.errorRed), 
                  foregroundColor: VoiceGuruTheme.errorRed, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ), 
                child: const Text('Clear Chat History'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                await SupabaseConfig.client.auth.signOut();
                if (mounted) Navigator.pushReplacementNamed(context, '/auth');
              }, 
              child: Text('Sign Out / Reset', style: GoogleFonts.outfit(color: VoiceGuruTheme.textSecondary, decoration: TextDecoration.underline))
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade100)),
      child: Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade700)),
    );
  }

  Widget _buildSection({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: VoiceGuruTheme.textSecondary)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: VoiceGuruTheme.backgroundLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildBoardChip(String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedBoard = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? VoiceGuruTheme.primaryPurple.withValues(alpha: 0.1) : VoiceGuruTheme.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? VoiceGuruTheme.primaryPurple : Colors.black.withValues(alpha: 0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected) const Icon(Icons.check, size: 16, color: VoiceGuruTheme.primaryPurple),
              if (isSelected) const SizedBox(width: 4),
              Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? VoiceGuruTheme.primaryPurple : VoiceGuruTheme.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParentUpdatesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: VoiceGuruTheme.successGreen),
              const SizedBox(width: 12),
              Text('Parent Updates', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Send weekly learning reports to your parent via WhatsApp. They will see what you explored and how you performed in quizzes.', style: GoogleFonts.outfit(fontSize: 13, color: VoiceGuruTheme.textSecondary, height: 1.4)),
          const SizedBox(height: 20),
          TextField(
            controller: _whatsappController,
            decoration: _inputDecoration('Parent\'s WhatsApp (with country code)').copyWith(prefixIcon: const Icon(Icons.phone_android_rounded, size: 20)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, 
            child: ElevatedButton.icon(
              onPressed: () async {
                final phone = _whatsappController.text;
                if (phone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a phone number')));
                  return;
                }
                await ApiClient.get('/api/v1/reports/send-now?parent_phone=$phone');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report sent to WhatsApp!')));
                }
              }, 
              icon: const Icon(Icons.send_rounded), 
              label: const Text('Send Weekly Report Now'), 
              style: ElevatedButton.styleFrom(backgroundColor: VoiceGuruTheme.successGreen, foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
