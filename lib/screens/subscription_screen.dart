// lib/screens/subscription_screen.dart - ПОЛНОСТЬЮ ОБНОВЛЕННАЯ ВЕРСИЯ
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/providers/subscription_provider.dart';
import 'package:alertme/providers/language_provider.dart';
import 'package:alertme/screens/activation_code_screen.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final isPremium = subscriptionProvider.isPremium;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('subscription')),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Если уже Premium
            if (isPremium) ...[
              _buildCurrentPremiumCard(context, subscriptionProvider),
              const SizedBox(height: AppSpacing.lg),
            ],
            
            Text(
              lang.translate('premium_features'),
              style: context.textStyles.displaySmall?.semiBold,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildFeatureItem(Icons.people, lang.translate('unlimited_contacts')),
            _buildFeatureItem(Icons.location_on, 'Геозоны (безопасные/опасные зоны)'),
            _buildFeatureItem(Icons.history, lang.translate('location_history')),
            _buildFeatureItem(Icons.support_agent, 'Приоритетная поддержка 24/7'),
            _buildFeatureItem(Icons.security, 'Расширенные настройки безопасности'),
            
            const SizedBox(height: AppSpacing.xxl),
            
            _buildPricingCard(context, lang),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Кнопка активации кода
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ActivationCodeScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.vpn_key),
                label: const Text('Активировать код из Telegram'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.softCyan,
                  foregroundColor: AppColors.navyBlack,
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Инструкция
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
                      'Оплатите в Telegram боте @AlertMePremiumBot и получите код активации',
                      style: context.textStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPremiumCard(
    BuildContext context,
    SubscriptionProvider provider,
  ) {
    final subscription = provider.currentSubscription;
    if (subscription == null) return const SizedBox();

    return Card(
      color: AppColors.deepBlue.withValues(alpha: 0.05),
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium, color: AppColors.deepBlue),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Premium активен',
                  style: context.textStyles.titleLarge?.semiBold
                      .withColor(AppColors.deepBlue),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Действует до: ${subscription.endDate.day}.${subscription.endDate.month}.${subscription.endDate.year}',
              style: context.textStyles.bodyMedium,
            ),
            Text(
              'Осталось дней: ${subscription.daysRemaining}',
              style: context.textStyles.bodyMedium?.withColor(AppColors.textSecondary),
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
              style: context.textStyles.headlineMedium?.semiBold
                  .withColor(AppColors.deepBlue),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '100',
                  style: context.textStyles.displayLarge?.bold
                      .withColor(AppColors.deepBlue),
                ),
                const SizedBox(width: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Telegram',
                        style: context.textStyles.bodyMedium
                            ?.withColor(AppColors.textSecondary),
                      ),
                      Text(
                        'Stars/месяц',
                        style: context.textStyles.bodyMedium
                            ?.withColor(AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '≈ 199 сом/месяц',
              style: context.textStyles.bodyLarge?.semiBold,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Оплата через Telegram Stars',
              style: context.textStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}