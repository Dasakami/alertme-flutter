import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/providers/auth_provider.dart';
import 'package:alertme/providers/contact_provider.dart';
import 'package:alertme/providers/sos_provider.dart';
import 'package:alertme/services/location_service.dart';
import 'package:alertme/services/notification_service.dart';
import 'package:alertme/services/audio_service.dart'; // ИСПРАВЛЕНО
import 'package:alertme/screens/sos_active_screen.dart';
import 'dart:async';

class SOSConfirmationScreen extends StatefulWidget {
  const SOSConfirmationScreen({super.key});

  @override
  State<SOSConfirmationScreen> createState() => _SOSConfirmationScreenState();
}

class _SOSConfirmationScreenState extends State<SOSConfirmationScreen> {
  final AudioService _audioService = AudioService(); // ИСПРАВЛЕНО
  bool _isRecording = false;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initAndStartRecording();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _initAndStartRecording() async {
    await _audioService.init();
    await _startRecording();
  }

  Future<void> _startRecording() async {
    final success = await _audioService.startRecording();
    
    if (success) {
      setState(() => _isRecording = true);
      
      // Таймер записи
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() => _recordingSeconds++);
          
          // Останавливаем через 30 секунд
          if (_recordingSeconds >= 30) {
            _stopRecording();
          }
        }
      });
    }
  }

  Future<void> _stopRecording() async {
    await _audioService.stopRecording();
    _recordingTimer?.cancel();
    setState(() => _isRecording = false);
  }

  Future<void> _activateSOS(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final contactProvider = context.read<ContactProvider>();
    final sosProvider = context.read<SOSProvider>();
    final locationService = LocationService();
    final notificationService = NotificationService();

    // Останавливаем запись если идет
    String? audioPath;
    if (_isRecording) {
      audioPath = await _audioService.stopRecording();
    } else {
      audioPath = _audioService.recordingPath;
    }

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
          Navigator.pop(context);
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
        notes: audioPath != null ? 'С аудиозаписью' : null,
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
        
        // 5. Отправляем аудио в Telegram если есть
        if (audioPath != null) {
          final botToken = '7205482794:AAFstGWp1aOoLS_L_TNVX74aQzgwGDgKQy8';
          
          debugPrint('🎤 Аудио записано: $audioPath');
          
          // Отправляем аудио каждому контакту с Telegram username
          for (final contact in contacts) {
            if (contact.telegramUsername != null && contact.telegramUsername!.isNotEmpty) {
              debugPrint('📤 Попытка отправить аудио @${contact.telegramUsername}');
              
              // TODO: Получить chat_id из базы через API
              // Пока просто логируем
              // Когда бэкенд готов - раскомментировать:
              /*
              final chatId = await _getChatIdFromBackend(contact.telegramUsername);
              if (chatId != null) {
                await _audioService.sendAudioToTelegram(
                  botToken: botToken,
                  chatId: chatId,
                  audioPath: audioPath,
                  caption: '🚨 SOS от ${authProvider.currentUser?.name}\n'
                          '📍 ${location.address ?? "Неизвестно"}\n'
                          '⏰ ${DateTime.now().hour}:${DateTime.now().minute}',
                );
              }
              */
            }
          }
        }
        
        // 6. Звоним основному контакту
        await notificationService.callPrimaryContact(contacts);
      }

      // 7. Переходим на экран активного SOS
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
              
              // Индикатор записи
              if (_isRecording) ...[
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Запись аудио: ${_recordingSeconds}с / 30с',
                        style: context.textStyles.bodyLarge?.semiBold
                            .withColor(Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              
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
                    if (_isRecording || _audioService.recordingPath != null)
                      _buildActionItem(
                        Icons.mic,
                        'Аудиозапись (готовится)',
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
                        onPressed: () {
                          _audioService.cancelRecording();
                          Navigator.pop(context);
                        },
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