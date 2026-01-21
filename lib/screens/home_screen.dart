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
import 'package:alertme/screens/sos_active_screen.dart';
import 'package:alertme/widgets/sos_button.dart';
import 'package:alertme/widgets/mini_map.dart';
import 'package:alertme/widgets/quick_action_button.dart';
import 'package:alertme/services/location_service.dart';

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
    await authProvider.loadProfile();
    
    await Future.wait([
      contactProvider.loadContacts(),
      subscriptionProvider.loadCurrentSubscription(), 
      sosProvider.loadAlerts(),
    ]);
  }

  // 🚨 НОВАЯ ЛОГИКА: Быстрая активация SOS без аудио
  Future<void> _triggerQuickSOS() async {
    final contactProvider = context.read<ContactProvider>();
    final sosProvider = context.read<SOSProvider>();
    final locationService = LocationService();
    final lang = context.read<LanguageProvider>();

    if (contactProvider.contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.translate('add_contact_first')),
          backgroundColor: AppColors.sosRed,
        ),
      );
      return;
    }

    // Показываем индикатор загрузки
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      // Получаем местоположение
      final location = await locationService.getCurrentLocation();
      
      if (location == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(lang.isRussian 
                ? 'Не удалось определить местоположение'
                : 'Жайгашкан жерди аныктоо мүмкүн болгон жок'),
              backgroundColor: AppColors.sosRed,
            ),
          );
        }
        return;
      }

      // Мгновенная отправка SOS БЕЗ аудио
      final alert = await sosProvider.triggerSOS(
        latitude: location.latitude,
        longitude: location.longitude,
        address: location.address,
        activationMethod: 'button',
        notes: lang.isRussian ? 'Быстрая активация SOS' : 'Тез SOS активациялоо',
        audioPath: null, // НЕТ АУДИО
      );

      if (alert == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(sosProvider.error ?? lang.translate('activation_error')),
              backgroundColor: AppColors.sosRed,
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.pop(context); // Закрываем индикатор
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SOSActiveScreen()),
        );
      }

    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${lang.translate('error')}: $e'),
            backgroundColor: AppColors.sosRed,
          ),
        );
      }
    }
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
                                lang.translate('sos_active'),
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
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: AppSpacing.horizontalLg,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      const MiniMap(),
                      
                      const SizedBox(height: AppSpacing.xxl),
                      // ИЗМЕНЕНО: Одно нажатие вместо зажимания
                      SOSButton(onActivate: _triggerQuickSOS),
                      
                      const SizedBox(height: AppSpacing.xxl),
                      
                      Text(
                        lang.isRussian 
                          ? 'Нажмите для мгновенной отправки SOS'
                          : 'SOS дароо жөнөтүү үчүн басыңыз',
                        style: context.textStyles.bodyMedium?.withColor(
                          AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: AppSpacing.xxl),
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