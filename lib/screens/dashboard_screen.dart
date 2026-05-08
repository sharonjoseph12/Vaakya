import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../providers/chat_provider.dart';
import '../providers/voice_provider.dart';
import '../providers/profile_provider.dart';
import '../models/message_model.dart';
import 'camera_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollCtrl = ScrollController();
  late AnimationController _orbPulse;
  late AnimationController _orbRotation;

  @override
  void initState() {
    super.initState();
    _orbPulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _orbRotation = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();

    // Wire up providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chat = context.read<ChatProvider>();
      final voice = context.read<VoiceProvider>();
      final profile = context.read<ProfileProvider>();

      // Auto-scroll on new message
      chat.onNewMessage = _scrollToBottom;

      // Init voice engine
      voice.init();

      // On speech result → send to backend
      voice.onSpeechResult = (text) async {
        voice.setProcessing();
        final reply = await chat.sendMessage(
          query: text,
          profileId: profile.profileId,
          subject: 'General',
          language: profile.language,
          learnerLevel: profile.learnerLevel,
        );
        if (reply != null) {
          await voice.speak(reply, language: profile.language);
        } else {
          voice.setIdle();
        }
      };

      // Load demo profile
      profile.useDemoProfile();
      // Welcome message
      chat.addAiMessage(
          "Hi! I'm VoiceGuru 🎓 Tap the mic button and ask me anything about your studies!");
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _orbPulse.dispose();
    _orbRotation.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onOrbTap() {
    final voice = context.read<VoiceProvider>();
    if (voice.state == VoiceState.listening) {
      voice.stopListening();
    } else if (voice.state == VoiceState.speaking) {
      voice.stopSpeaking();
    } else if (voice.state == VoiceState.idle) {
      voice.startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: VoiceGuruTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('VoiceGuru',
                style: GoogleFonts.outfit(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: Colors.white)),
            Text('Hi, ${profile.childName}',
                style: GoogleFonts.outfit(
                    fontSize: 12, color: VoiceGuruTheme.textSecondary)),
          ]),
        ]),
        actions: [
          if (profile.streakCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: VoiceGuruTheme.warningAmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text('${profile.streakCount}',
                    style: GoogleFonts.outfit(
                        color: VoiceGuruTheme.warningAmber,
                        fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
            ),
          IconButton(
            icon: const Icon(Icons.camera_alt_rounded),
            tooltip: 'Scan Homework',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CameraScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.person_rounded),
            tooltip: 'Profile',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: Column(children: [
        // Offline banner
        Consumer<ChatProvider>(builder: (context, chat, child) {
          if (!chat.isOffline) return const SizedBox.shrink();
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: VoiceGuruTheme.warningAmber.withValues(alpha: 0.15),
            child: Text('📶  Offline mode — using cached answers',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 12, color: VoiceGuruTheme.warningAmber)),
          );
        }),

        // Chat messages
        Expanded(
          child: Consumer<ChatProvider>(builder: (context, chat, child) {
            return ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: chat.messages.length + (chat.isLoading ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == chat.messages.length && chat.isLoading) {
                  return _buildShimmerBubble();
                }
                return _buildChatBubble(chat.messages[i]);
              },
            );
          }),
        ),

        // Voice state indicator
        Consumer<VoiceProvider>(builder: (context, voice, child) {
          if (voice.state == VoiceState.listening &&
              voice.currentWords.isNotEmpty) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: VoiceGuruTheme.surfaceCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.mic, color: VoiceGuruTheme.errorRed, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(voice.currentWords,
                      style: GoogleFonts.outfit(
                          color: Colors.white, fontSize: 14),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ]),
            ).animate().fadeIn(duration: 200.ms);
          }
          return const SizedBox.shrink();
        }),

        const SizedBox(height: 8),
        // Voice Orb
        _buildVoiceOrb(),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildChatBubble(MessageModel msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isUser ? VoiceGuruTheme.userBubbleGradient : null,
          color: isUser ? null : VoiceGuruTheme.surfaceCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: (isUser ? VoiceGuruTheme.primaryPurple : Colors.black)
                  .withValues(alpha: 0.15),
              blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(msg.text,
              style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 14.5, height: 1.45)),
          const SizedBox(height: 4),
          Text(
            '${msg.timestamp.hour.toString().padLeft(2, '0')}:'
            '${msg.timestamp.minute.toString().padLeft(2, '0')}',
            style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.45), fontSize: 10),
          ),
        ]),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildShimmerBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Shimmer.fromColors(
        baseColor: VoiceGuruTheme.surfaceCard,
        highlightColor: VoiceGuruTheme.surfaceElevated,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.65,
          height: 60,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: VoiceGuruTheme.surfaceCard,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceOrb() {
    return Consumer<VoiceProvider>(builder: (context, voice, child) {
      return GestureDetector(
        onTap: _onOrbTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_orbPulse, _orbRotation]),
          builder: (context, _) {
            return _orbContent(voice.state);
          },
        ),
      );
    });
  }

  Widget _orbContent(VoiceState state) {
    final double size = 72;
    final IconData icon;
    final List<BoxShadow> shadows;
    Widget? overlay;

    switch (state) {
      case VoiceState.idle:
        icon = Icons.mic_none_rounded;
        shadows = [
          BoxShadow(
            color: const Color(0xFF3B82F6)
                .withValues(alpha: 0.25 + _orbPulse.value * 0.25),
            blurRadius: 20 + _orbPulse.value * 15,
            spreadRadius: 2,
          ),
        ];
        break;
      case VoiceState.listening:
        icon = Icons.mic_rounded;
        shadows = [
          BoxShadow(
            color: VoiceGuruTheme.errorRed
                .withValues(alpha: 0.3 + _orbPulse.value * 0.35),
            blurRadius: 24 + _orbPulse.value * 18,
            spreadRadius: 4,
          ),
        ];
        // Ripple ring
        overlay = Container(
          width: size + 20 + _orbPulse.value * 16,
          height: size + 20 + _orbPulse.value * 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: VoiceGuruTheme.errorRed
                  .withValues(alpha: 0.5 - _orbPulse.value * 0.4),
              width: 2,
            ),
          ),
        );
        break;
      case VoiceState.processing:
        icon = Icons.hourglass_top_rounded;
        shadows = [
          BoxShadow(
            color: VoiceGuruTheme.primaryPurple.withValues(alpha: 0.4),
            blurRadius: 25, spreadRadius: 3),
        ];
        // Rotating ring
        overlay = Transform.rotate(
          angle: _orbRotation.value * 2 * math.pi,
          child: Container(
            width: size + 14, height: size + 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.transparent, width: 3),
              gradient: SweepGradient(colors: [
                VoiceGuruTheme.primaryPurple,
                VoiceGuruTheme.secondaryCyan,
                VoiceGuruTheme.primaryPurple.withValues(alpha: 0),
              ]),
            ),
          ),
        );
        break;
      case VoiceState.speaking:
        icon = Icons.volume_up_rounded;
        shadows = [
          BoxShadow(
            color: VoiceGuruTheme.successGreen
                .withValues(alpha: 0.2 + _orbPulse.value * 0.2),
            blurRadius: 20 + _orbPulse.value * 12,
            spreadRadius: 2,
          ),
        ];
        break;
    }

    final gradient = switch (state) {
      VoiceState.idle => VoiceGuruTheme.orbIdleGradient,
      VoiceState.listening => VoiceGuruTheme.orbListeningGradient,
      VoiceState.processing => VoiceGuruTheme.orbProcessingGradient,
      VoiceState.speaking => const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)]),
    };

    final label = switch (state) {
      VoiceState.idle => 'Tap to ask',
      VoiceState.listening => 'Listening…',
      VoiceState.processing => 'Thinking…',
      VoiceState.speaking => 'Speaking…',
    };

    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: size + 30, height: size + 30,
        child: Stack(alignment: Alignment.center, children: [
          overlay ?? const SizedBox.shrink(),
          Container(
            width: size, height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradient,
              boxShadow: shadows,
            ),
            child: Icon(icon, size: 30, color: Colors.white),
          ),
        ]),
      ),
      const SizedBox(height: 6),
      Text(label,
          style: GoogleFonts.outfit(
              color: VoiceGuruTheme.textSecondary,
              fontSize: 11, fontWeight: FontWeight.w500)),
    ]);
  }
}
