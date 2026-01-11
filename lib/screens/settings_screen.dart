import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/providers/auth_provider.dart';
import 'package:alertme/providers/subscription_provider.dart';
import 'package:alertme/providers/language_provider.dart';
import 'package:alertme/models/user.dart'; 
import 'package:alertme/screens/subscription_screen.dart';
import 'package:alertme/screens/onboarding_screen.dart';
import 'package:alertme/screens/profile_edit_screen.dart'; 
import 'package:alertme/screens/notifications_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    try {
      final subscriptionProvider = context.read<SubscriptionProvider>();
      await subscriptionProvider.loadCurrentSubscription();
    } catch (e) {
      debugPrint('❌ Ошибка загрузки подписки: $e');
    }
  }

  Future<void> _refreshSubscription() async {
    final lang = context.read<LanguageProvider>();
    try {
      await context.read<SubscriptionProvider>().loadCurrentSubscription();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.translate('data_updated')),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Ошибка обновления: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('settings')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSubscription,
            tooltip: lang.translate('refresh'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSubscription,
        child: ListView(
          padding: AppSpacing.paddingLg,
          children: [
            _buildProfileCard(context, lang, user),
            const SizedBox(height: AppSpacing.lg),
            
            // Язык
            _buildSettingsTile(
              context,
              lang,
              icon: Icons.language,
              title: lang.translate('language'),
              subtitle: lang.isRussian ? 'Русский' : 'Кыргызча',
              onTap: () => _showLanguageDialog(context, lang),
            ),
            
            // Подписка
            _buildSubscriptionTile(context, lang, user),
            
            // Уведомления
            _buildSettingsTile(
              context,
              lang,
              icon: Icons.notifications_outlined,
              title: lang.translate('notifications'),
              subtitle: lang.translate('notifications_settings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsSettingsScreen(),
                  ),
                );
              },
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Выход
            _buildSettingsTile(
              context,
              lang,
              icon: Icons.logout,
              title: lang.translate('logout'),
              titleColor: AppColors.sosRed,
              onTap: () => _logout(context, lang, authProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionTile(
    BuildContext context,
    LanguageProvider lang,
    UserModel user,
  ) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final isPremium = user.isPremium;
    
    String subtitle;
    Color? titleColor;
    bool showArrow = false;

    if (subscriptionProvider.isLoading) {
      subtitle = lang.translate('loading');
    } else if (isPremium) {
      subtitle = '${lang.translate('premium')} ✅';
      titleColor = AppColors.softCyan;
      
      if (subscriptionProvider.currentSubscription != null) {
        final endDate = subscriptionProvider.currentSubscription!.endDate;
        final days = subscriptionProvider.currentSubscription!.daysRemaining;
        subtitle += '\n${lang.translate('valid_until')} ${endDate.day}.${endDate.month}.${endDate.year}';
        subtitle += ' (${lang.translate('days_remaining')}: $days ${lang.translate('days')})';
      }
    } else {
      subtitle = lang.translate('free');
      showArrow = true;
    }

    return Card(
      child: ListTile(
        leading: Icon(
          Icons.workspace_premium,
          color: isPremium ? AppColors.softCyan : AppColors.deepBlue,
        ),
        title: Text(
          lang.translate('subscription'),
          style: context.textStyles.bodyLarge?.copyWith(color: titleColor),
        ),
        subtitle: Text(
          subtitle,
          style: context.textStyles.bodyMedium?.withColor(AppColors.textSecondary),
        ),
        trailing: showArrow ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
          ).then((_) => _refreshSubscription());
        },
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, LanguageProvider lang, UserModel user) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.deepBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, size: 32, color: AppColors.deepBlue),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: context.textStyles.titleLarge?.semiBold),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        user.phoneNumber,
                        style: context.textStyles.bodyMedium?.withColor(AppColors.textSecondary),
                      ),
                      if (user.telegramUsername != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            const Icon(Icons.telegram, size: 14, color: AppColors.softCyan),
                            const SizedBox(width: 4),
                            Text(
                              '@${user.telegramUsername}',
                              style: context.textStyles.bodySmall?.withColor(AppColors.softCyan),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
                  );
                },
                icon: const Icon(Icons.edit),
                label: Text(lang.translate('edit_profile')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    LanguageProvider lang, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: titleColor ?? AppColors.deepBlue),
        title: Text(
          title,
          style: context.textStyles.bodyLarge?.copyWith(color: titleColor),
        ),
        subtitle: subtitle != null
          ? Text(subtitle, style: context.textStyles.bodyMedium?.withColor(AppColors.textSecondary))
          : null,
        trailing: trailing ?? (onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null),
        onTap: onTap,
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Русский'),
              value: 'ru',
              groupValue: lang.currentLanguage,
              onChanged: (value) {
                if (value != null) {
                  lang.setLanguage(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Кыргызча'),
              value: 'kg',
              groupValue: lang.currentLanguage,
              onChanged: (value) {
                if (value != null) {
                  lang.setLanguage(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context, LanguageProvider lang, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('logout_question')),
        content: Text(lang.translate('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.sosRed),
            child: Text(lang.translate('logout')),
          ),
        ],
      ),
    );
  }
}