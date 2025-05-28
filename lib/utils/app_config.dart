class AppConfig {
  static const String frontendUrl = String.fromEnvironment(
    'FRONTEND_URL',
    defaultValue: 'https://heavensconnect.com',  // fallback prod domain
  );
}
