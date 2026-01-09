// lib/screens/home_screen.dart - ОБНОВЛЕННАЯ ВЕРСИЯ
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/providers/auth_provider.dart';
import 'package:alertme/providers/contact_provider.dart';
import 'package:alertme/providers/sos_provider.dart';
import 'package:alertme/providers/subscription_provider.dart';
import 'package:alertme/providers/language_provider.dart';
import 'package:alertme/screens/contacts_screen.dart';
import 'package:alertme/screens/safety_timer_screen.dart';
import 'package:alertme/screens/settings_screen.dart';
import 'package:alertme/screens/sos_confirmation_screen.dart';  // НОВОЕ
import 'package:alertme/widgets/sos_button.dart';
import 'package:alertme/widgets/mini_map.dart';
import 'package:alertme/widgets/quick_action_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final contactProvider = context.read<ContactProvider>();
    final subscriptionProvider = context.read<SubscriptionProvider>();
    final sosProvider = context.read<SOSProvider>();

    // ✅ Загружаем профиль (с is_premium)
    await authProvider.loadProfile();
    
    await Future.wait([
      contactProvider.loadContacts(),
      subscriptionProvider.loadCurrentSubscription(), // Тихо
      sosProvider.loadAlerts(),
    ]);
  }

  // ИЗМЕНЕНО: Теперь открываем экран подтверждения
  void _triggerSOS() {
    final contactProvider = context.read<ContactProvider>();

    // Проверка контактов
    if (contactProvider.contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Добавьте хотя бы один экстренный контакт'),
          backgroundColor: AppColors.sosRed,
        ),
      );
      return;
    }

    // Открываем экран подтверждения
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SOSConfirmationScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final sosProvider = Provider.of<SOSProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Шапка
            Padding(
              padding: AppSpacing.horizontalLg + AppSpacing.verticalMd,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.translate('app_name'),
                        style: context.textStyles.titleLarge?.semiBold,
                      ),
                      Text(
                        authProvider.currentUser?.name ?? '',
                        style: context.textStyles.bodyMedium?.withColor(
                          AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Индикатор активного SOS
                      if (sosProvider.hasActiveAlert)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.sosRed,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'SOS активен',
                                style: context.textStyles.labelSmall?.withColor(
                                  Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        ),
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Контент
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: AppSpacing.horizontalLg,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      
                      // Карта
                      const MiniMap(),
                      
                      const SizedBox(height: AppSpacing.xxl),
                      
                      // SOS кнопка
                      SOSButton(onActivate: _triggerSOS),
                      
                      const SizedBox(height: AppSpacing.xxl),
                      
                      Text(
                        lang.translate('hold_for_sos'),
                        style: context.textStyles.bodyMedium?.withColor(
                          AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: AppSpacing.xxl),
                      
                      // Быстрые действия
                      Row(
                        children: [
                          Expanded(
                            child: QuickActionButton(
                              icon: Icons.people_outline,
                              label: lang.translate('contacts'),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ContactsScreen(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: QuickActionButton(
                              icon: Icons.timer_outlined,
                              label: lang.translate('timer'),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SafetyTimerScreen(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}