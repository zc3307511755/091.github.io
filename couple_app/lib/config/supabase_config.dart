class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'your-publishable-or-anon-key',
  );

  static bool get isConfigured =>
      !url.contains('your-project') &&
      !publishableKey.contains('your-publishable-or-anon-key');
}
