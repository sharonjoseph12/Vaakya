import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/supabase_config.dart';
import 'core/theme.dart';
import 'providers/chat_provider.dart';
import 'providers/voice_provider.dart';
import 'core/local_db.dart';
import 'providers/profile_provider.dart';
import 'providers/gamification_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/role_screen.dart';
import 'screens/faculty_dashboard.dart';
import 'screens/parent_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // PERF FIX: Disable runtime font fetching — uses bundled/system fallback
  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialize Supabase
  await SupabaseConfig.init();

  // Pre-seed offline database with educational content
  LocalDatabase.instance.seedIfNeeded();

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
                'Oops! Vaakya needs\na quick nap 😴',
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

  runApp(const VaakyaApp());
}

class VaakyaApp extends StatelessWidget {
  const VaakyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
        ChangeNotifierProvider(create: (_) => GamificationProvider()..loadFromPrefs()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Vaakya',
            debugShowCheckedModeBanner: false,
            theme: VoiceGuruTheme.lightTheme,
            darkTheme: VoiceGuruTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/role',
            routes: {
              '/role': (_) => const RoleScreen(),
              '/auth': (_) => const AuthScreen(),
              '/dashboard': (_) => const DashboardScreen(),
              '/faculty': (_) => const FacultyDashboard(),
              '/parent': (_) => const ParentDashboard(),
            },
          );
        },
      ),
    );
  }
}
