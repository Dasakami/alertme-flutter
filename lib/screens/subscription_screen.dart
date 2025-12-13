import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/providers/auth_provider.dart';
import 'package:alertme/providers/language_provider.dart';
import 'package:alertme/models/user.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(lang.translate('subscription'))),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.translate('premium_features'),
              style: context.textStyles.displaySmall?.semiBold,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildFeatureItem(Icons.people, lang.translate('unlimited_contacts')),
            _buildFeatureItem(Icons.history, lang.translate('location_history')),
            _buildFeatureItem(Icons.support_agent, 'Приоритетная поддержка'),
            _buildFeatureItem(Icons.security, 'Расширенные настройки безопасности'),
            const SizedBox(height: AppSpacing.xxl),
            _buildPricingCard(context, lang),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _upgradeToPremium(context, lang),
                child: Text(lang.translate('subscribe')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: AppSpacing.verticalSm,
      child: Row(
        children: [
          Icon(icon, color: AppColors.softCyan, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(BuildContext context, LanguageProvider lang) {
    return Card(
      color: AppColors.deepBlue.withValues(alpha: 0.05),
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          children: [
            Text(
              'Premium',
              style: context.textStyles.headlineMedium?.semiBold.withColor(AppColors.deepBlue),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '499',
                  style: context.textStyles.displayLarge?.bold.withColor(AppColors.deepBlue),
                ),
                const SizedBox(width: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'сом/месяц',
                    style: context.textStyles.bodyLarge?.withColor(AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Отмена в любое время',
              style: context.textStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _upgradeToPremium(BuildContext context, LanguageProvider lang) async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    await Future.delayed(const Duration(seconds: 2));

    final updatedUser = user.copyWith(
      subscriptionTier: SubscriptionTier.premium,
      updatedAt: DateTime.now(),
    );

    await authProvider.updateUser(updatedUser);

    if (context.mounted) {
      Navigator.pop(context);
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Добро пожаловать в Premium!'),
          backgroundColor: AppColors.softCyan,
        ),
      );
    }
  }
}