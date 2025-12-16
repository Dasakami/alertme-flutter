import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/providers/auth_provider.dart';
import 'package:alertme/providers/contact_provider.dart';
import 'package:alertme/providers/sos_provider.dart';
import 'package:alertme/services/location_service.dart';
import 'package:alertme/services/notification_service.dart';
import 'package:alertme/screens/sos_active_screen.dart';

class SOSConfirmationScreen extends StatelessWidget {
  const SOSConfirmationScreen({super.key});

  Future<void> _activateSOS(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final contactProvider = context.read<ContactProvider>();
    final sosProvider = context.read<SOSProvider>();
    final locationService = LocationService();
    final notificationService = NotificationService();

    // Показываем загрузку
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // 1. Получаем местоположение
      final location = await locationService.getCurrentLocation();
      
      if (location == null) {
        if (context.mounted) {
          Navigator.pop(context); // Закрываем загрузку
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось определить местоположение'),
              backgroundColor: AppColors.sosRed,
            ),
          );
        }
        return;
      }

      // 2. Активируем SOS на сервере
      final alert = await sosProvider.triggerSOS(
        latitude: location.latitude,
        longitude: location.longitude,
        address: location.address,
        activationMethod: 'button',
      );

      if (alert == null) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(sosProvider.error ?? 'Ошибка активации'),
              backgroundColor: AppColors.sosRed,
            ),
          );
        }
        return;
      }

      // 3. Генерируем сообщение
      final message = notificationService.generateSOSMessage(
        userName: authProvider.currentUser?.name ?? 'Пользователь',
        latitude: location.latitude,
        longitude: location.longitude,
        address: location.address,
      );

      // 4. Отправляем SMS всем контактам
      final contacts = contactProvider.contacts;
      if (contacts.isNotEmpty) {
        await notificationService.sendSOSToAll(contacts, message);
        
        // 5. Звоним основному контакту
        await notificationService.callPrimaryContact(contacts);
      }

      // 6. Переходим на экран активного SOS
      if (context.mounted) {
        Navigator.pop(context); // Закрываем загрузку
        Navigator.pop(context); // Закрываем экран подтверждения
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SOSActiveScreen()),
        );
      }

    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: AppColors.sosRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactProvider = context.watch<ContactProvider>();
    
    return Scaffold(
      backgroundColor: AppColors.sosRed,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.paddingXl,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_rounded,
                size: 100,
                color: Colors.white,
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              Text(
                'Активировать SOS?',
                style: context.textStyles.displaySmall?.semiBold
                    .withColor(Colors.white),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              Container(
                padding: AppSpacing.paddingLg,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Будет отправлено:',
                      style: context.textStyles.bodyLarge?.semiBold
                          .withColor(Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildActionItem(
                      Icons.sms,
                      'SMS всем контактам (${contactProvider.contacts.length})',
                    ),
                    _buildActionItem(
                      Icons.phone,
                      'Звонок основному контакту',
                    ),
                    _buildActionItem(
                      Icons.location_on,
                      'Ваше местоположение',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white, width: 2),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Отмена'),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _activateSOS(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.sosRed,
                        ),
                        child: const Text('АКТИВИРОВАТЬ'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
        ],
      ),
    );
  }
}