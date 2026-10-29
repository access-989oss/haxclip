import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../theme/hax_theme.dart';
import '../widgets/hax_logo.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _serverUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _apiService = ApiService();

  bool _isTesting = false;
  bool _isLoadingProfile = false;
  String? _testResult;
  bool _testSuccess = false;

  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _serverUrlController.text = AppConfig.backendUrl;
    _apiKeyController.text = AppConfig.apiKey;
    _loadProfile();
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoadingProfile = true);
    try {
      final profile = await _apiService.fetchUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoadingProfile = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = 'Testing connection to VPS...';
      _testSuccess = false;
    });

    try {
      AppConfig.backendUrl = _serverUrlController.text.trim();
      AppConfig.apiKey = _apiKeyController.text.trim();

      final healthy = await _apiService.checkHealth();
      if (!healthy) {
        throw Exception('Server health check failed.');
      }

      final profile = await _apiService.fetchUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _testSuccess = true;
          _testResult = 'Connected to VPS! Authenticated as ${profile['name'] ?? 'User'}';
          _isTesting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testSuccess = false;
          _testResult = 'Connection failed: ${e.toString().replaceAll('Exception:', '').trim()}';
          _isTesting = false;
        });
      }
    }
  }

  void _saveSettings() {
    AppConfig.backendUrl = _serverUrlController.text.trim();
    AppConfig.apiKey = _apiKeyController.text.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: HaxTheme.emeraldAccent,
        content: const Text(
          'Settings saved successfully',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _resetDefaults() {
    setState(() {
      _serverUrlController.text = AppConfig.defaultBackendUrl;
      _apiKeyController.text = AppConfig.defaultApiKey;
      AppConfig.backendUrl = AppConfig.defaultBackendUrl;
      AppConfig.apiKey = AppConfig.defaultApiKey;
    });
    _testConnection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HaxTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: HaxTheme.bgSurface,
        elevation: 0,
        title: const Text(
          'Settings & Auth',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload Profile',
            onPressed: _loadProfile,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // User Account Card
          _buildUserCard(),
          const SizedBox(height: 24),

          // Backend Server URL Section
          _buildSectionHeader('VPS Backend Connection', Icons.dns_rounded),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _serverUrlController,
            label: 'Server URL',
            hint: 'https://...',
            prefixIcon: Icons.link_rounded,
          ),
          const SizedBox(height: 16),

          // API Key Section
          _buildSectionHeader('Authentication API Key', Icons.key_rounded),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _apiKeyController,
            label: 'API Key',
            hint: 'sk_haxclip_...',
            obscureText: true,
            prefixIcon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 20),

          // Test & Save buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isTesting ? null : _testConnection,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.wifi_tethering_rounded, size: 18),
                  label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HaxTheme.bgSurfaceElevated,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: HaxTheme.borderGlow),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Save Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HaxTheme.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (_testResult != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _testSuccess
                    ? HaxTheme.emeraldAccent.withValues(alpha: 0.12)
                    : Colors.redAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _testSuccess ? HaxTheme.emeraldAccent : Colors.redAccent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _testSuccess ? Icons.check_circle : Icons.error_outline,
                    color: _testSuccess ? HaxTheme.emeraldAccent : Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _testResult!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _testSuccess ? HaxTheme.emeraldAccent : Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Engine Status Badges
          _buildSectionHeader('Processing Engine Architecture', Icons.memory_rounded),
          const SizedBox(height: 12),
          _buildEngineCard(
            'VPS Host Server',
            '172.236.182.92 (FastAPI 0.2.0)',
            Icons.cloud_done_rounded,
            HaxTheme.cyanAccent,
          ),
          const SizedBox(height: 8),
          _buildEngineCard(
            'Video Processing',
            'FFmpeg 7.1.5 (Active on VPS Worker)',
            Icons.movie_filter_rounded,
            HaxTheme.emeraldAccent,
          ),
          const SizedBox(height: 8),
          _buildEngineCard(
            'Speech-To-Text AI',
            'AssemblyAI Streaming Engine',
            Icons.record_voice_over_rounded,
            const Color(0xFFA855F7),
          ),
          const SizedBox(height: 8),
          _buildEngineCard(
            'Viral Hook LLM',
            'Gemini AI / Hosted Intelligence',
            Icons.psychology_rounded,
            const Color(0xFFF59E0B),
          ),

          const SizedBox(height: 28),
          OutlinedButton(
            onPressed: _resetDefaults,
            style: OutlinedButton.styleFrom(
              foregroundColor: HaxTheme.textMuted,
              side: BorderSide(color: HaxTheme.borderGlow),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Reset to Default VPS Settings'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildUserCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HaxTheme.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HaxTheme.borderGlow),
      ),
      child: _isLoadingProfile
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          : Row(
              children: [
                const HaxLogo(size: 52),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userProfile?['name'] ?? 'HaxClip User',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userProfile?['email'] ?? 'Authenticated via API Key',
                        style: TextStyle(
                          fontSize: 13,
                          color: HaxTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: HaxTheme.cyanAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: HaxTheme.cyanAccent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'PLAN: ${(_userProfile?['plan'] ?? 'PRO').toString().toUpperCase()}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: HaxTheme.cyanAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: HaxTheme.cyanAccent),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: HaxTheme.textSecondary, fontSize: 13),
        hintText: hint,
        hintStyle: TextStyle(color: HaxTheme.textMuted, fontSize: 12),
        prefixIcon: Icon(prefixIcon, color: HaxTheme.textSecondary, size: 18),
        filled: true,
        fillColor: HaxTheme.bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: HaxTheme.borderGlow),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: HaxTheme.borderGlow),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: HaxTheme.cyanAccent),
        ),
      ),
    );
  }

  Widget _buildEngineCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: HaxTheme.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HaxTheme.borderGlow),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: HaxTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
