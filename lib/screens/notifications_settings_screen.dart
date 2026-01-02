import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alertme/theme.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _sosAlerts = true;
  bool _timerAlerts = true;
  bool _geozoneAlerts = true;
  bool _pushNotifications = true;
  bool _smsNotifications = true;
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
      _timerAlerts = prefs.getBool('notif_timer') ?? true;
      _geozoneAlerts = prefs.getBool('notif_geozone') ?? true;
      _pushNotifications = prefs.getBool('notif_push') ?? true;
      _smsNotifications = prefs.getBool('notif_sms') ?? true;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки уведомлений'),
      ),
      body: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          // Типы уведомлений
          _buildSectionHeader('Типы уведомлений'),
          _buildSwitchTile(
            title: 'SOS сигналы',
            subtitle: 'Уведомления об экстренных ситуациях',
            icon: Icons.emergency,
            value: _sosAlerts,
            onChanged: (value) {
              setState(() => _sosAlerts = value);
              _saveSetting('notif_sos', value);
            },
          ),
          _buildSwitchTile(
            title: 'Таймеры безопасности',
            subtitle: 'Истечение таймеров активности',
            icon: Icons.timer,
            value: _timerAlerts,
            onChanged: (value) {
              setState(() => _timerAlerts = value);
              _saveSetting('notif_timer', value);
            },
          ),
          _buildSwitchTile(
            title: 'Геозоны',
            subtitle: 'Вход/выход из безопасных зон',
            icon: Icons.location_on,
            value: _geozoneAlerts,
            onChanged: (value) {
              setState(() => _geozoneAlerts = value);
              _saveSetting('notif_geozone', value);
            },
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Каналы уведомлений
          _buildSectionHeader('Каналы уведомлений'),
          _buildSwitchTile(
            title: 'Push-уведомления',
            subtitle: 'Уведомления в приложении',
            icon: Icons.notifications,
            value: _pushNotifications,
            onChanged: (value) {
              setState(() => _pushNotifications = value);
              _saveSetting('notif_push', value);
            },
          ),
          _buildSwitchTile(
            title: 'SMS уведомления',
            subtitle: 'Отправка SMS экстренным контактам',
            icon: Icons.sms,
            value: _smsNotifications,
            onChanged: (value) {
              setState(() => _smsNotifications = value);
              _saveSetting('notif_sms', value);
            },
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Поведение
          _buildSectionHeader('Поведение'),
          _buildSwitchTile(
            title: 'Звук',
            subtitle: 'Звуковые сигналы при уведомлениях',
            icon: Icons.volume_up,
            value: _soundEnabled,
            onChanged: (value) {
              setState(() => _soundEnabled = value);
              _saveSetting('notif_sound', value);
            },
          ),
          _buildSwitchTile(
            title: 'Вибрация',
            subtitle: 'Вибрация при уведомлениях',
            icon: Icons.vibration,
            value: _vibrationEnabled,
            onChanged: (value) {
              setState(() => _vibrationEnabled = value);
              _saveSetting('notif_vibration', value);
            },
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
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
                    'SOS уведомления всегда отправляются вне зависимости от настроек',
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
              onPressed: _testNotification,
              icon: const Icon(Icons.send),
              label: const Text('Отправить тестовое уведомление'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        title,
        style: context.textStyles.titleMedium?.semiBold
            .withColor(AppColors.deepBlue),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      child: SwitchListTile(
        secondary: Icon(icon, color: AppColors.deepBlue),
        title: Text(title, style: context.textStyles.bodyLarge),
        subtitle: Text(subtitle, style: context.textStyles.bodySmall),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.deepBlue,
      ),
    );
  }

  void _testNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: AppSpacing.sm),
            Text('Тестовое уведомление отправлено'),
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