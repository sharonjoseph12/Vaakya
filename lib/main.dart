import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/supabase_config.dart';
import 'core/theme.dart';
import 'providers/chat_provider.dart';
import 'providers/voice_provider.dart';
import 'providers/profile_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseConfig.init();

  // Custom error widget — friendly screen instead of Red Screen of Death
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: VoiceGuruTheme.surfaceDark,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: VoiceGuruTheme.warningAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.sentiment_dissatisfied_rounded,
                    size: 40, color: VoiceGuruTheme.warningAmber),
              ),
              const SizedBox(height: 20),
              Text(
                'Oops! VoiceGuru needs\na quick nap 😴',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Something went wrong. Try going back.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: VoiceGuruTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(const VoiceGuruApp());
}

class VoiceGuruApp extends StatelessWidget {
  const VoiceGuruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
      ],
      child: MaterialApp(
        title: 'VoiceGuru',
        debugShowCheckedModeBanner: false,
        theme: VoiceGuruTheme.darkTheme,
        initialRoute: '/auth',
        routes: {
          '/auth': (_) => const AuthScreen(),
          '/dashboard': (_) => const DashboardScreen(),
        },
      ),
    );
  }
}
