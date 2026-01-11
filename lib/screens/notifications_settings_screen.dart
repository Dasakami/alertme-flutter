import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/providers/language_provider.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _sosAlerts = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _sosAlerts = prefs.getBool('notif_sos') ?? true;
      _soundEnabled = prefs.getBool('notif_sound') ?? true;
      _vibrationEnabled = prefs.getBool('notif_vibration') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('notifications_settings')),
      ),
      body: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          // SOS уведомления
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: SwitchListTile(
              secondary: const Icon(Icons.emergency, color: AppColors.sosRed),
              title: Text(
                lang.translate('sos_alerts'),
                style: context.textStyles.bodyMedium?.semiBold,
              ),
              subtitle: Text(
                lang.translate('sos_alerts_desc'),
                style: context.textStyles.bodySmall,
              ),
              value: _sosAlerts,
              onChanged: (value) {
                setState(() => _sosAlerts = value);
                _saveSetting('notif_sos', value);
              },
              activeColor: AppColors.deepBlue,
            ),
          ),
          
          // Звук
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: SwitchListTile(
              secondary: const Icon(Icons.volume_up, color: AppColors.deepBlue),
              title: Text(
                lang.translate('sound'),
                style: context.textStyles.bodyMedium?.semiBold,
              ),
              subtitle: Text(
                lang.translate('sound_desc'),
                style: context.textStyles.bodySmall,
              ),
              value: _soundEnabled,
              onChanged: (value) {
                setState(() => _soundEnabled = value);
                _saveSetting('notif_sound', value);
              },
              activeColor: AppColors.deepBlue,
            ),
          ),
          
          // Вибрация
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: SwitchListTile(
              secondary: const Icon(Icons.vibration, color: AppColors.deepBlue),
              title: Text(
                lang.translate('vibration'),
                style: context.textStyles.bodyMedium?.semiBold,
              ),
              subtitle: Text(
                lang.translate('vibration_desc'),
                style: context.textStyles.bodySmall,
              ),
              value: _vibrationEnabled,
              onChanged: (value) {
                setState(() => _vibrationEnabled = value);
                _saveSetting('notif_vibration', value);
              },
              activeColor: AppColors.deepBlue,
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Информация
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: AppColors.softCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.softCyan),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.softCyan, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    lang.translate('sos_always_sent'),
                    style: context.textStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Кнопка теста
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _testNotification(lang),
              icon: const Icon(Icons.send),
              label: Text(lang.translate('send_test_notification')),
            ),
          ),
        ],
      ),
    );
  }

  void _testNotification(LanguageProvider lang) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: AppSpacing.sm),
            Text(lang.translate('test_notification_sent')),
          ],
        ),
        backgroundColor: AppColors.softCyan,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}