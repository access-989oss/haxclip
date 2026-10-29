class AppConfig {
  static const String appName = 'HaxClip';
  static const String appTagline = 'AI-Powered 3D Video Clipping';
  
  // VPS Backend URL via persistent Cloudflare tunnel
  static const String defaultBackendUrl = 'https://cars-asian-later-fuel.trycloudflare.com';
  
  // Dedicated Mobile API Key generated for VPS backend
  static const String defaultApiKey = 'sk_haxclip_Ay6WVg1YJVAFQyf8stUIbhEoOPc571TvjlWEMqxaLtE';
  
  static String backendUrl = defaultBackendUrl;
  static String apiKey = defaultApiKey;
}
