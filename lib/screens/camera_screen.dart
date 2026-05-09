import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../providers/chat_provider.dart';
import '../providers/voice_provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _image;
  bool _sending = false;
  String? _error;
  final _picker = ImagePicker();

  Future<void> _capture() async {
    final picked = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 85);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _pickGallery() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _send() async {
    if (_image == null) return;
    setState(() { _sending = true; _error = null; });

    final bytes = await _image!.readAsBytes();
    final base64Img = base64Encode(bytes);
    final reply = await ApiClient.describeImage(base64Img);

    if (!mounted) return;

    if (reply != null) {
      final chat = context.read<ChatProvider>();
      final voice = context.read<VoiceProvider>();
      chat.addUserMessage('📸 [Homework Photo]');
      chat.addAiMessage(reply);
      voice.speak(reply);
      Navigator.pop(context);
    } else {
      setState(() {
        _error = "I can't quite read that image. Can you take a sharper photo?";
        _sending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Homework',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Expanded(
            child: _image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.file(_image!, fit: BoxFit.contain),
                  ).animate().fadeIn(duration: 300.ms).scale(
                      begin: const Offset(0.95, 0.95),
                      end: const Offset(1, 1))
                : Container(
                    decoration: BoxDecoration(
                      color: VoiceGuruTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: VoiceGuruTheme.surfaceElevated, width: 2),
                    ),
                    child: Center(
                      child: Column(
                          mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.camera_alt_rounded,
                            size: 64,
                            color: VoiceGuruTheme.textSecondary
                                .withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text('Take a photo of your homework',
                            style: GoogleFonts.outfit(
                                color: VoiceGuruTheme.textSecondary,
                                fontSize: 14)),
                        Text('Vaakya will give you a hint!',
                            style: GoogleFonts.outfit(
                                color: VoiceGuruTheme.textSecondary
                                    .withValues(alpha: 0.6),
                                fontSize: 12)),
                      ]),
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: VoiceGuruTheme.warningAmber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded,
                    color: VoiceGuruTheme.warningAmber, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!,
                    style: GoogleFonts.outfit(
                        color: VoiceGuruTheme.warningAmber, fontSize: 13))),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // Action buttons
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _sending ? null : _capture,
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Camera'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: VoiceGuruTheme.secondaryCyan,
                  side: const BorderSide(color: VoiceGuruTheme.secondaryCyan),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _sending ? null : _pickGallery,
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Gallery'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: VoiceGuruTheme.primaryPurpleLight,
                  side: const BorderSide(
                      color: VoiceGuruTheme.primaryPurpleLight),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          if (_image != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded),
                label: Text(_sending ? 'Analyzing…' : 'Send to Vaakya'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
