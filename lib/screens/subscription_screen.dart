import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/providers/subscription_provider.dart';
import 'package:alertme/providers/auth_provider.dart';
import 'package:alertme/providers/language_provider.dart';
import 'package:alertme/screens/activation_code_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<SubscriptionProvider>();
    await provider.loadPlans();
    await provider.loadCurrentSubscription();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final lang = context.watch<LanguageProvider>();
    final user = authProvider.currentUser;

    if (user == null) return Scaffold(body: Center(child: Text(lang.translate('error'))));

    final isPremium = user.isPremium;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('subscription')),
      ),
      body: subscriptionProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isPremium) 
                    _buildActivePremiumCard(subscriptionProvider, lang)
                  else 
                    _buildFreeStatusCard(lang),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  if (!isPremium)
                    _buildActivateCodeButton(context, lang)
                  else
                    _buildExtendSubscriptionButton(context, lang),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  _buildFeaturesList(lang),
                ],
              ),
            ),
    );
  }

  Widget _buildActivePremiumCard(SubscriptionProvider provider, LanguageProvider lang) {
    final subscription = provider.currentSubscription;
    final endDate = subscription?.endDate;
    
    return Container(
      padding: AppSpacing.paddingXl,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.softCyan, AppColors.deepBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.softCyan.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.workspace_premium,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            lang.translate('premium_active'),
            style: context.textStyles.headlineSmall?.semiBold.withColor(Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (endDate != null) ...[
            Text(
              '${lang.translate('valid_until')} ${endDate.day}.${endDate.month}.${endDate.year}',
              style: context.textStyles.bodyLarge?.withColor(Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${lang.translate('days_remaining')}: ${subscription?.daysRemaining ?? 0} ${lang.translate('days')}',
              style: context.textStyles.bodyMedium?.semiBold.withColor(Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFreeStatusCard(LanguageProvider lang) {
    return Container(
      padding: AppSpacing.paddingXl,
      decoration: BoxDecoration(
        color: AppColors.deepBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.deepBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.lock_outline,
            size: 64,
            color: AppColors.deepBlue,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            lang.translate('free_plan'),
            style: context.textStyles.headlineSmall?.semiBold,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            lang.translate('activate_premium'),
            style: context.textStyles.bodyLarge?.withColor(AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivateCodeButton(BuildContext context, LanguageProvider lang) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ActivationCodeScreen()),
          );
        },
        icon: const Icon(Icons.vpn_key),
        label: Text(lang.translate('activate_code')),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.softCyan,
        ),
      ),
    );
  }

  Widget _buildExtendSubscriptionButton(BuildContext context, LanguageProvider lang) {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ActivationCodeScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(lang.translate('extend_subscription')),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.softCyan,
          side: const BorderSide(color: AppColors.softCyan, width: 2),
        ),
      ),
    );
  }

  Widget _buildFeaturesList(LanguageProvider lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.translate('premium_benefits'),
          style: context.textStyles.titleLarge?.semiBold,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildFeatureItem(
          icon: Icons.people,
          title: lang.translate('unlimited_contacts'),
          description: lang.translate('unlimited_contacts_desc'),
        ),
        _buildFeatureItem(
          icon: Icons.location_on,
          title: lang.translate('geozones'),
          description: lang.translate('geozones_desc'),
        ),
        _buildFeatureItem(
          icon: Icons.history,
          title: lang.translate('location_history'),
          description: lang.translate('location_history_desc'),
        ),
        _buildFeatureItem(
          icon: Icons.telegram,
          title: lang.translate('telegram_sos'),
          description: lang.translate('telegram_sos_desc'),
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.softCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: AppColors.softCyan),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textStyles.bodyLarge?.semiBold,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: context.textStyles.bodyMedium?.withColor(AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}