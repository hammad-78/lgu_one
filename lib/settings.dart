import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';
import 'utils/flushbar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _appLink =
      'https://play.google.com/store/apps/details?id=com.lgu.app&pcampaignid=web_share';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeController = ThemeController.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Don\'t hide it from your friends!',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/lgu_qr_code.png',
                        width: 220,
                        height: 220,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Scan the QR code to download the app.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _copyAppLink(context),
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy link'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _shareApp(context),
                            icon: const Icon(Icons.share),
                            label: const Text('Share app'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          _settingsTile(
            child: ListTile(
              leading: Icon(
                _themeIcon(themeController.themeMode),
                color: theme.colorScheme.primary,
              ),
              title: const Text('Theme'),
              subtitle: Text(_themeModeLabel(themeController.themeMode)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => _showThemePicker(context, themeController),
            ),
          ),
          _settingsTile(
            child: ListTile(
              leading: Icon(Icons.cached, color: theme.colorScheme.primary),
              title: const Text('Clear Cache'),
              subtitle: const Text('Clear saved notification history'),
              onTap: () => _clearCache(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Card(margin: EdgeInsets.zero, child: child),
    );
  }

  Future<void> _copyAppLink(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _appLink));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('App link copied.')));
  }

  Future<void> _shareApp(BuildContext context) async {
    try {
      final result = await Share.share(
        'Download LGU Connect from the Play Store:\n$_appLink',
        subject: 'LGU Connect',
      );
      if (result.status == ShareResultStatus.unavailable && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No apps are available to share.')),
        );
      }
    } on PlatformException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open sharing options.')),
      );
    }
  }

  IconData _themeIcon(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.dark => Icons.dark_mode,
      ThemeMode.system => Icons.brightness_auto,
      ThemeMode.light => Icons.light_mode,
    };
  }

  String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.dark => 'Dark mode',
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light mode',
    };
  }

  Future<void> _showThemePicker(
    BuildContext context,
    ThemeController themeController,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _themeOption(
              mode: ThemeMode.light,
              title: 'Light mode',
              icon: Icons.light_mode,
              selectedMode: themeController.themeMode,
              onSelected: () =>
                  _selectThemeMode(context, ThemeMode.light, themeController),
            ),
            _themeOption(
              mode: ThemeMode.dark,
              title: 'Dark mode',
              icon: Icons.dark_mode,
              selectedMode: themeController.themeMode,
              onSelected: () =>
                  _selectThemeMode(context, ThemeMode.dark, themeController),
            ),
            _themeOption(
              mode: ThemeMode.system,
              title: 'System',
              icon: Icons.brightness_auto,
              selectedMode: themeController.themeMode,
              onSelected: () =>
                  _selectThemeMode(context, ThemeMode.system, themeController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeOption({
    required ThemeMode mode,
    required String title,
    required IconData icon,
    required ThemeMode selectedMode,
    required VoidCallback onSelected,
  }) {
    final selected = mode == selectedMode;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: selected ? const Icon(Icons.check) : null,
      selected: selected,
      onTap: onSelected,
    );
  }

  void _selectThemeMode(
    BuildContext context,
    ThemeMode mode,
    ThemeController themeController,
  ) {
    themeController.setThemeMode(mode);
    Navigator.pop(context);
  }

  Future<void> _clearCache(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final selectedTheme = prefs.getString('theme_mode');
    await prefs.clear(); // also removes the remembered LGU student email
    if (selectedTheme != null) {
      await prefs.setString('theme_mode', selectedTheme);
    }
    await FirebaseAuth.instance.signOut();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await CachedNetworkImageProvider.defaultCacheManager.emptyCache();
    if (!context.mounted) return;
    await showFlushbar(
      context,
      'Cache history cleared successfully.',
      color: Colors.green.shade900,
      icon: Icons.check_circle_outline,
    );
  }
}
