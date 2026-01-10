import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/providers/subscription_provider.dart';
import 'package:alertme/providers/auth_provider.dart';
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
    final user = authProvider.currentUser;

    if (user == null) return const Scaffold(body: Center(child: Text('Ошибка загрузки')));

    // ✅ Проверяем is_premium пользователя
    final isPremium = user.isPremium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Подписка'),
      ),
      body: subscriptionProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ✅ СТАТУС ПОДПИСКИ
                  if (isPremium) 
                    _buildActivePremiumCard(subscriptionProvider)
                  else 
                    _buildFreeStatusCard(),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // ✅ КНОПКА АКТИВАЦИИ КОДА
                  if (!isPremium)
                    _buildActivateCodeButton(context)
                  else
                    _buildExtendSubscriptionButton(context),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Преимущества Premium
                  _buildFeaturesList(),
                ],
              ),
            ),
    );
  }

  /// ✅ КАРТОЧКА АКТИВНОЙ ПОДПИСКИ
  Widget _buildActivePremiumCard(SubscriptionProvider provider) {
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
            '✨ Premium Активен',
            style: context.textStyles.headlineSmall?.semiBold.withColor(Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (endDate != null) ...[
            Text(
              'Действует до ${endDate.day}.${endDate.month}.${endDate.year}',
              style: context.textStyles.bodyLarge?.withColor(Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Осталось ${subscription?.daysRemaining ?? 0} дней',
              style: context.textStyles.bodyMedium?.semiBold.withColor(Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// ✅ КАРТОЧКА FREE ПЛАНА
  Widget _buildFreeStatusCard() {
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
            'Free План',
            style: context.textStyles.headlineSmall?.semiBold,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Активируйте Premium для полного доступа',
            style: context.textStyles.bodyLarge?.withColor(AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// ✅ КНОПКА АКТИВАЦИИ КОДА (для Free пользователей)
  Widget _buildActivateCodeButton(BuildContext context) {
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
        label: const Text('Активировать код из Telegram'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.softCyan,
        ),
      ),
    );
  }

  /// ✅ КНОПКА ПРОДЛЕНИЯ (для Premium пользователей)
  Widget _buildExtendSubscriptionButton(BuildContext context) {
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
        label: const Text('Продлить подписку'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.softCyan,
          side: const BorderSide(color: AppColors.softCyan, width: 2),
        ),
      ),
    );
  }

  /// Список преимуществ Premium
  Widget _buildFeaturesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Преимущества Premium:',
          style: context.textStyles.titleLarge?.semiBold,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildFeatureItem(
          icon: Icons.people,
          title: 'Неограниченное количество контактов',
          description: 'Добавляйте сколько угодно близких',
        ),
        _buildFeatureItem(
          icon: Icons.location_on,
          title: 'Геозоны',
          description: 'Уведомления при входе/выходе из зон',
        ),
        _buildFeatureItem(
          icon: Icons.history,
          title: 'История местоположений',
          description: 'Просмотр истории передвижений',
        ),
        _buildFeatureItem(
          icon: Icons.telegram,
          title: 'SOS в Telegram',
          description: 'Мгновенные уведомления в мессенджер',
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