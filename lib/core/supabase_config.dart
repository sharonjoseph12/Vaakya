import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const String _supabaseUrl =
      'https://nsgpkkngknpfxkwwlwtb.supabase.co';

  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5zZ3Bra25na25wZnhrd3dsd3RiIiwi'
      'cm9sZSI6ImFub24iLCJpYXQiOjE3NzgyMTU5MzIsImV4cCI6MjA5Mzc5MTkzMn0'
      '.F5tctMrS42AmphSyeTaAGeZnJXojlXK3QuV3SZrdFOo';

  /// Initialize the Supabase client. Call once in main().
  static Future<void> init() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  /// Convenience accessor for the Supabase client.
  static SupabaseClient get client => Supabase.instance.client;
}
