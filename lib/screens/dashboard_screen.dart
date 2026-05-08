import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/chat_provider.dart';
import '../providers/voice_provider.dart';
import '../providers/profile_provider.dart';
import '../core/supabase_config.dart';
import '../models/message_model.dart';
import 'camera_screen.dart';
import 'profile_screen.dart';
import 'quiz_screen.dart';
import '../core/theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = context.read<ProfileProvider>();
      final chat = context.read<ChatProvider>();

      final session = SupabaseConfig.client.auth.currentSession;
      if (session != null) {
        profile.loadFirstChildForParent(session.user.id);
      } else {
        profile.useDemoProfile();
      }

      if (chat.messages.isEmpty) {
        chat.addAiMessage("Hi! I'm VoiceGuru 🎓 Tap the mic button and ask me anything about your studies!");
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final chat = context.watch<ChatProvider>();
    final voice = context.watch<VoiceProvider>();

    return Scaffold(
      backgroundColor: VoiceGuruTheme.backgroundLight,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const Icon(Icons.school, color: VoiceGuruTheme.primaryPurple),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('VoiceGuru', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: VoiceGuruTheme.primaryPurple)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: VoiceGuruTheme.successGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: VoiceGuruTheme.successGreen.withValues(alpha: 0.2)),
                      ),
                      child: Text('Lv.1 Making progress 📚', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: VoiceGuruTheme.successGreen)),
                    ),
                  ],
                ),
                Text('Hi ${profile.childName} 👋', style: GoogleFonts.outfit(fontSize: 14, color: VoiceGuruTheme.textSecondary, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.leaderboard_rounded), onPressed: () => Navigator.pushNamed(context, '/leaderboard')),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: VoiceGuruTheme.primaryPurple,
                child: Text(profile.childName.isNotEmpty ? profile.childName[0].toUpperCase() : 'S', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Streak Progress Card ──────────────────────────────────────────
          _buildStreakCard(),

          // ── Chat View ─────────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: chat.messages.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _buildIntroOwl();
                final msg = chat.messages[index - 1];
                return _buildChatBubble(msg);
              },
            ),
          ),

          // ── Greeting & Input Area ────────────────────────────────────────
          _buildInputArea(voice, chat, profile),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: VoiceGuruTheme.primaryPurple.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.bedtime_rounded, color: VoiceGuruTheme.primaryPurple),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Start your streak today!', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16)),
                Text('0/5 today', style: GoogleFonts.outfit(color: VoiceGuruTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Row(
            children: List.generate(5, (i) => Container(
              margin: const EdgeInsets.only(left: 4),
              width: 12, height: 12,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black12), color: Colors.transparent),
            )),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildIntroOwl() {
    return Column(
      children: [
        const Icon(Icons.emoji_emotions, size: 80, color: VoiceGuruTheme.accentOrange),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)]),
          child: Text(
            "I'm VoiceGuru, your study buddy! 🎒\nI can answer questions and read your homework!",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500, height: 1.4),
          ),
        ),
        const SizedBox(height: 40),
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good afternoon,', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800)),
              Text('Siddharth sanjay! ☀️', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: VoiceGuruTheme.primaryPurple)),
              const SizedBox(height: 8),
              Text('What would you like to explore today?', style: GoogleFonts.outfit(color: VoiceGuruTheme.textSecondary, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    ).animate().fadeIn(duration: 800.ms);
  }

  Widget _buildChatBubble(MessageModel msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? VoiceGuruTheme.primaryPurple : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
          boxShadow: [if (!isUser) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 5)],
        ),
        child: Text(msg.text, style: GoogleFonts.outfit(color: isUser ? Colors.white : VoiceGuruTheme.textPrimary, fontSize: 15, height: 1.4)),
      ),
    ).animate().scale(duration: 300.ms, curve: Curves.easeOut);
  }

  Widget _buildInputArea(VoiceProvider voice, ChatProvider chat, ProfileProvider profile) {
    final isListening = voice.state == VoiceState.listening;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))]),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isListening ? Colors.red : VoiceGuruTheme.primaryPurple,
            child: IconButton(
              icon: Icon(isListening ? Icons.stop : Icons.mic, color: Colors.white),
              onPressed: () {
                if (isListening) {
                  voice.stopListening();
                } else {
                  voice.onSpeechResult = (text) {
                    if (text.isNotEmpty) {
                      chat.sendMessage(
                        query: text,
                        profileId: profile.profileId,
                        subject: 'General',
                        language: profile.language,
                        learnerLevel: profile.learnerLevel,
                      );
                    }
                  };
                  voice.startListening();
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: VoiceGuruTheme.backgroundLight, borderRadius: BorderRadius.circular(30)),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.add_photo_alternate_outlined, color: VoiceGuruTheme.textSecondary), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraScreen()))),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Type your question...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 12)),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          chat.sendMessage(
                            query: val.trim(),
                            profileId: profile.profileId,
                            subject: 'General',
                            language: profile.language,
                            learnerLevel: profile.learnerLevel,
                          );
                          _controller.clear();
                          _scrollToBottom();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: VoiceGuruTheme.primaryPurple,
      unselectedItemColor: VoiceGuruTheme.textSecondary,
      selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_rounded), label: 'Learn'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Progress'),
        BottomNavigationBarItem(icon: Icon(Icons.quiz_rounded), label: 'Daily Quiz'),
      ],
      onTap: (index) {
        if (index == 1) Navigator.pushNamed(context, '/analytics');
        if (index == 2) {
          final profile = context.read<ProfileProvider>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuizScreen(
                childId: profile.profileId,
                subject: 'General',
              ),
            ),
          );
        }
      },
    );
  }
}
