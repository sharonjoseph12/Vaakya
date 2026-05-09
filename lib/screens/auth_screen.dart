import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../core/theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String? _error;
  late AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _glow.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    // Ensure phone starts with country code
    final formattedPhone = phone.startsWith('+') ? phone : '+91$phone';
    setState(() { _loading = true; _error = null; });
    try {
      await SupabaseConfig.client.auth.signInWithOtp(phone: formattedPhone)
          .timeout(const Duration(seconds: 8));
      _phoneCtrl.text = formattedPhone;
      setState(() => _otpSent = true);
    } on TimeoutException {
      setState(() => _error = 'Request timed out. Check your internet connection.');
    } catch (e) {
      setState(() => _error = 'Could not send OTP: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim().isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      await SupabaseConfig.client.auth.verifyOTP(
        type: OtpType.sms,
        phone: _phoneCtrl.text.trim(),
        token: _otpCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pushReplacementNamed('/dashboard');
    } catch (e) {
      setState(() => _error = 'Invalid OTP.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _demo() => Navigator.of(context).pushReplacementNamed('/dashboard');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0F1A), Color(0xFF1A1030), Color(0xFF0F0F1A)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo ──
                  AnimatedBuilder(
                    animation: _glow,
                    builder: (context, _) => Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: VoiceGuruTheme.orbIdleGradient,
                        boxShadow: [
                          BoxShadow(
                            color: VoiceGuruTheme.primaryPurple
                                .withValues(alpha: 0.3 + _glow.value * 0.3),
                            blurRadius: 30 + _glow.value * 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.record_voice_over_rounded,
                          size: 44, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('VoiceGuru',
                      style: GoogleFonts.outfit(
                          fontSize: 36, fontWeight: FontWeight.w800,
                          color: Colors.white, letterSpacing: -1)),
                  const SizedBox(height: 6),
                  Text('Your AI Study Companion',
                      style: GoogleFonts.outfit(
                          fontSize: 15, color: VoiceGuruTheme.textSecondary)),
                  const SizedBox(height: 48),

                  if (!_otpSent) ...[
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.outfit(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '+91 9876543210',
                        prefixIcon: const Icon(Icons.phone_rounded,
                            color: VoiceGuruTheme.primaryPurple),
                        label: Text('Phone Number',
                            style: GoogleFonts.outfit(
                                color: VoiceGuruTheme.textSecondary)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _sendOtp,
                        child: _loading
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Send OTP'),
                      ),
                    ),
                  ],

                  if (_otpSent) ...[
                    Text('Enter the OTP sent to ${_phoneCtrl.text}',
                        style: GoogleFonts.outfit(
                            color: VoiceGuruTheme.textSecondary, fontSize: 14),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _otpCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.outfit(
                          color: Colors.white, fontSize: 24, letterSpacing: 12),
                      textAlign: TextAlign.center, maxLength: 6,
                      decoration: InputDecoration(
                        hintText: '• • • • • •', counterText: '',
                        hintStyle: GoogleFonts.outfit(
                            color: VoiceGuruTheme.textSecondary,
                            letterSpacing: 12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _verifyOtp,
                        child: _loading
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Verify & Login'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _otpSent = false; _otpCtrl.clear();
                      }),
                      child: Text('Change number',
                          style: GoogleFonts.outfit(
                              color: VoiceGuruTheme.secondaryCyan)),
                    ),
                  ],

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: VoiceGuruTheme.errorRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline,
                            color: VoiceGuruTheme.errorRed, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!,
                            style: GoogleFonts.outfit(
                                color: VoiceGuruTheme.errorRed, fontSize: 13))),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 40),
                  // ── Demo Mode ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: VoiceGuruTheme.surfaceElevated),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(children: [
                      Text('For Development',
                          style: GoogleFonts.outfit(
                              color: VoiceGuruTheme.textSecondary,
                              fontSize: 12)),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _demo,
                          icon: const Icon(Icons.science_rounded),
                          label: const Text('Skip to Demo Mode'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: VoiceGuruTheme.secondaryCyan,
                            side: const BorderSide(
                                color: VoiceGuruTheme.secondaryCyan),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
