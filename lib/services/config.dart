// 配置文件模板
// 复制此文件为 config_local.dart 并填入真实密钥
// config_local.dart 不会被提交到 Git

class AppConfig {
  // Gemini API Key
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
  
  // Supabase 配置
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  // 支付宝配置
  static const String alipayAppId = 'YOUR_ALIPAY_APP_ID';
}
