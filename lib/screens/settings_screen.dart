import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/providers/auth_provider.dart';
import 'package:alertme/providers/subscription_provider.dart';
import 'package:alertme/providers/language_provider.dart';
import 'package:alertme/models/user.dart'; // ДОБАВЛЕНО
import 'package:alertme/screens/subscription_screen.dart';
import 'package:alertme/screens/onboarding_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(title: Text(lang.translate('settings'))),
      body: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          _buildProfileCard(context, user),
          const SizedBox(height: AppSpacing.lg),
          _buildSettingsTile(
            context,
            icon: Icons.language,
            title: lang.translate('language'),
            subtitle: lang.isRussian ? 'Русский' : 'Кыргызча',
            onTap: () => _showLanguageDialog(context, lang),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.workspace_premium,
            title: lang.translate('subscription'),
            subtitle: subscriptionProvider.isPremium // ИСПРАВЛЕНО
              ? lang.translate('premium')
              : lang.translate('free'),
            trailing: !subscriptionProvider.isPremium // ИСПРАВЛЕНО
              ? const Icon(Icons.arrow_forward_ios, size: 16)
              : null,
            onTap: () {
              if (!subscriptionProvider.isPremium) { // ИСПРАВЛЕНО
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                );
              }
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.notifications_outlined,
            title: lang.translate('notifications'),
            subtitle: 'Включены',
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSettingsTile(
            context,
            icon: Icons.logout,
            title: lang.translate('logout'),
            titleColor: AppColors.sosRed,
            onTap: () => _logout(context, authProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, UserModel user) { // ИСПРАВЛЕНО: User -> UserModel
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Row(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
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

  void _logout(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
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
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}
