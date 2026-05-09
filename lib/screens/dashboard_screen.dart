import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../providers/chat_provider.dart';
import '../providers/voice_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/gamification_provider.dart';
import '../models/message_model.dart';
import 'camera_screen.dart';
import 'profile_screen.dart';
import 'quiz_screen.dart';
import 'badges_screen.dart';
import 'analytics_screen.dart';
import 'notes_screen.dart';
import 'study_materials_screen.dart';
import '../core/local_db.dart';
import '../core/pdf_generator.dart';
import 'flashcard_screen.dart';
import 'games_hub_screen.dart';
import 'depth_engine_screen.dart';
import '../widgets/concept_diagram.dart';
import '../widgets/premium_background.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _textCtrl = TextEditingController();
  late AnimationController _orbPulse;
  late AnimationController _orbRotation;
  bool _showTextInput = false;

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
      final gp = context.read<GamificationProvider>();

      // Auto-scroll on new message
      chat.onNewMessage = _scrollToBottom;

      // Track questions for analytics
      chat.onQuestionTracked = (subject) {
        gp.onQuestionAsked(subject: subject);
      };

      // "Quiz me" voice command
      chat.onQuizRequested = (subject) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(subject: subject.isNotEmpty ? subject : 'Science')));
      };

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
          userName: profile.childName,
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
          "Hi! I'm Vaakya 🎓 Tap the mic button and ask me anything about your studies!");
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _textCtrl.dispose();
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
    final profile = context.read<ProfileProvider>();
    if (voice.state == VoiceState.listening) {
      voice.stopListening();
    } else if (voice.state == VoiceState.speaking) {
      voice.stopSpeaking();
    } else if (voice.state == VoiceState.idle) {
      voice.startListening(localeId: profile.language.replaceAll('-', '_'));
    }
  }

  void _sendTextMessage() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    setState(() => _showTextInput = false);

    final chat = context.read<ChatProvider>();
    final profile = context.read<ProfileProvider>();
    chat.sendMessage(
      query: text,
      profileId: profile.profileId,
      subject: 'General',
      language: profile.language,
      learnerLevel: profile.learnerLevel,
      userName: profile.childName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset('assets/images/logo.png', width: 36, height: 36),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Vaakya',
                style: GoogleFonts.outfit(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            Text('Hi, ${profile.childName}',
                style: GoogleFonts.outfit(
                    fontSize: 12, color: isDark ? VoiceGuruTheme.textSecondary : VoiceGuruTheme.textSecondaryLight)),
          ]),
        ]),
        actions: [
          // Theme toggle
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
            onPressed: () => themeProvider.toggleTheme(),
          ),
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
            icon: const Icon(Icons.person_rounded),
            tooltip: 'Profile',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: isDark ? VoiceGuruTheme.surfaceDark : VoiceGuruTheme.surfaceLight,
        child: Column(children: [
          DrawerHeader(
            decoration: const BoxDecoration(gradient: VoiceGuruTheme.primaryGradient),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school_rounded, size: 48, color: Colors.white),
                  const SizedBox(height: 10),
                  Text('Learning Hub', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.quiz_rounded, color: VoiceGuruTheme.primaryPurple),
            title: Text('Daily Quiz', style: GoogleFonts.outfit()),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events_rounded, color: VoiceGuruTheme.warningAmber),
            title: Text('My Badges', style: GoogleFonts.outfit()),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BadgesScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics_rounded, color: VoiceGuruTheme.secondaryCyan),
            title: Text('Analytics', style: GoogleFonts.outfit()),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.waves_rounded, color: Color(0xFF9D4EDD)),
            title: Text('Depth Engine', style: GoogleFonts.outfit()),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DepthEngineScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_rounded, color: Color(0xFF6C63FF)),
            title: Text('Study Materials', style: GoogleFonts.outfit()),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyMaterialsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.style_rounded, color: Color(0xFF00D2FF)),
            title: Text('Flashcards', style: GoogleFonts.outfit()),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FlashcardScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.sports_esports_rounded, color: Color(0xFFFF6584)),
            title: Text('Games', style: GoogleFonts.outfit()),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GamesHubScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.bookmark_rounded, color: Color(0xFFFFD700)),
            title: Text('Saved Notes', style: GoogleFonts.outfit()),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFFF6584)),
            title: Text('Export Chat as PDF', style: GoogleFonts.outfit()),
            onTap: () {
              Navigator.pop(context);
              final chat = context.read<ChatProvider>();
              final profile = context.read<ProfileProvider>();
              if (chat.messages.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No chat to export!')));
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('📄 Generating PDF...', style: GoogleFonts.outfit()), backgroundColor: const Color(0xFF6C63FF)));
              PdfGenerator.generateChatPdf(
                messages: chat.messages.map((m) => {'role': m.isUser ? 'user' : 'ai', 'text': m.text}).toList(),
                studentName: profile.childName,
              );
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text('Vaakya v1.0', style: GoogleFonts.outfit(color: VoiceGuruTheme.textSecondary, fontSize: 12)),
          ),
        ]),
      ),
      body: PremiumBackground(child: Column(children: [
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
                color: isDark ? VoiceGuruTheme.surfaceCard : VoiceGuruTheme.surfaceCardLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.mic, color: VoiceGuruTheme.errorRed, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(voice.currentWords,
                      style: GoogleFonts.outfit(fontSize: 14),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ]),
            ).animate().fadeIn(duration: 200.ms);
          }
          return const SizedBox.shrink();
        }),

        // Expandable text input
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _showTextInput
              ? Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _textCtrl,
                        autofocus: true,
                        style: GoogleFonts.outfit(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Type your question...',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: isDark ? VoiceGuruTheme.surfaceCard : VoiceGuruTheme.surfaceElevatedLight,
                        ),
                        onSubmitted: (_) => _sendTextMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: VoiceGuruTheme.primaryGradient,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        onPressed: _sendTextMessage,
                      ),
                    ),
                  ]),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 4),
        // Bottom bar: keyboard | mic orb | camera
        _buildBottomBar(),
        const SizedBox(height: 16),
      ])),
    );
  }

  Widget _buildBottomBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Keyboard toggle
        _buildBottomButton(
          icon: _showTextInput ? Icons.keyboard_hide_rounded : Icons.keyboard_rounded,
          label: 'Type',
          onTap: () => setState(() => _showTextInput = !_showTextInput),
        ),
        // Mic orb (center)
        _buildVoiceOrb(),
        // Camera
        _buildBottomButton(
          icon: Icons.camera_alt_rounded,
          label: 'Scan',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CameraScreen())),
        ),
      ],
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = context.read<ThemeProvider>().isDark;
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: isDark ? VoiceGuruTheme.surfaceCard : VoiceGuruTheme.surfaceElevatedLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 22, color: VoiceGuruTheme.primaryPurple),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.outfit(
            fontSize: 10, color: isDark ? VoiceGuruTheme.textSecondary : VoiceGuruTheme.textSecondaryLight)),
      ]),
    );
  }

  Widget _buildChatBubble(MessageModel msg) {
    final isUser = msg.isUser;
    final isDark = context.read<ThemeProvider>().isDark;
    final bubble = Container(
      margin: EdgeInsets.only(
          bottom: 12, left: isUser ? 48 : 0, right: isUser ? 0 : 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser
            ? VoiceGuruTheme.primaryPurple
            : (isDark ? VoiceGuruTheme.surfaceCard : VoiceGuruTheme.surfaceElevatedLight),
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
                color: isUser ? Colors.white : (isDark ? Colors.white : VoiceGuruTheme.textPrimaryLight),
                fontSize: 14.5, height: 1.45)),
        const SizedBox(height: 4),
        Text(
          '${msg.timestamp.hour.toString().padLeft(2, '0')}:'
          '${msg.timestamp.minute.toString().padLeft(2, '0')}',
          style: GoogleFonts.outfit(
              color: (isUser ? Colors.white : (isDark ? Colors.white : Colors.black))
                  .withValues(alpha: 0.45),
              fontSize: 10),
        ),
        if (!isUser && msg.sourcePage != null && msg.sourcePage!.startsWith('http')) ...[
          const SizedBox(height: 12),
          _buildYoutubeCard(msg.sourcePage!),
        ],
      ]),
    );
    // AI messages: concept diagram + action buttons + long-press bookmark
    if (!isUser) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
          onLongPress: () async {
            await LocalDatabase.instance.addBookmark(msg.text, topic: _lastTopic());
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('📌 Saved to Notes!', style: GoogleFonts.outfit()), backgroundColor: const Color(0xFF6C63FF), duration: const Duration(seconds: 2)),
              );
            }
          },
          child: bubble,
        ),
        // Visual concept diagram
        ConceptDiagram(topic: msg.text),
        // Quick action row
        Padding(
          padding: const EdgeInsets.only(right: 48, bottom: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _bubbleAction(Icons.picture_as_pdf_rounded, 'PDF', const Color(0xFFFF6584), () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('📄 Generating PDF...', style: GoogleFonts.outfit()), backgroundColor: const Color(0xFF6C63FF), duration: const Duration(seconds: 1)));
              PdfGenerator.generateAndShareNotes(notes: [{'text': msg.text, 'topic': _lastTopic(), 'created_at': msg.timestamp.toIso8601String()}], title: 'Vaakya - ${_lastTopic()}');
            }),
            const SizedBox(width: 8),
            _bubbleAction(Icons.bookmark_add_rounded, 'Save', const Color(0xFFFFD700), () async {
              await LocalDatabase.instance.addBookmark(msg.text, topic: _lastTopic());
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('📌 Saved!', style: GoogleFonts.outfit()), backgroundColor: const Color(0xFF6C63FF), duration: const Duration(seconds: 1)));
            }),
            const SizedBox(width: 8),
            _bubbleAction(Icons.style_rounded, 'Flashcard', const Color(0xFF00D2FF), () async {
              await LocalDatabase.instance.addFlashcard(front: _lastTopic(), back: msg.text.length > 200 ? msg.text.substring(0, 200) : msg.text);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🃏 Added to Flashcards!', style: GoogleFonts.outfit()), backgroundColor: const Color(0xFF00D2FF), duration: const Duration(seconds: 1)));
            }),
          ]),
        ),
      ]).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0);
    }
    return bubble.animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _bubbleAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.outfit(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  String _lastTopic() {
    final msgs = context.read<ChatProvider>().messages;
    for (int i = msgs.length - 1; i >= 0; i--) {
      if (msgs[i].isUser) return msgs[i].text.substring(0, msgs[i].text.length.clamp(0, 30));
    }
    return 'Study Note';
  }

  Widget _buildYoutubeCard(String url) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF0000), Color(0xFFCC0000)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('📺 Watch Related Video', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Tap to open on YouTube', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11)),
                ]),
              ),
              const Icon(Icons.open_in_new_rounded, size: 18, color: Colors.white70),
            ]),
          ),
        ),
      ),
    );
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
              fontSize: 11, fontWeight: FontWeight.w500)),
    ]);
  }
}
