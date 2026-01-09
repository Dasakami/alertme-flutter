import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/providers/auth_provider.dart';
import 'package:alertme/providers/contact_provider.dart';
import 'package:alertme/providers/sos_provider.dart';
import 'package:alertme/services/location_service.dart';
import 'package:alertme/services/audio_service.dart';
import 'package:alertme/screens/sos_active_screen.dart';
import 'dart:async';

class SOSConfirmationScreen extends StatefulWidget {
  const SOSConfirmationScreen({super.key});

  @override
  State<SOSConfirmationScreen> createState() => _SOSConfirmationScreenState();
}

class _SOSConfirmationScreenState extends State<SOSConfirmationScreen> {
  final AudioService _audioService = AudioService();
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
      
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() => _recordingSeconds++);
          
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

  /// ✅ ИСПРАВЛЕНО: Активация SOS
  Future<void> _activateSOS(BuildContext context) async {
    final sosProvider = context.read<SOSProvider>();
    final locationService = LocationService();

    // Останавливаем запись если идет
    String? audioPath;
    if (_isRecording) {
      audioPath = await _audioService.stopRecording();
    } else {
      audioPath = _audioService.recordingPath;
    }

    debugPrint('🎤 Путь к аудио: $audioPath');

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

      // 2. ✅ ИСПРАВЛЕНО: Активируем SOS с правильным названием параметра
      final alert = await sosProvider.triggerSOS(
        latitude: location.latitude,
        longitude: location.longitude,
        address: location.address,
        activationMethod: 'button',
        notes: audioPath != null ? 'С аудиозаписью' : null,
        audioPath: audioPath,  // ← ИСПРАВЛЕНО: audioPath вместо audioFilePath
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

      debugPrint('✅ SOS создан с ID: ${alert.id}');
      debugPrint('✅ Аудио отправлено: ${audioPath != null}');

      // 3. Переходим на экран активного SOS
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
                      Icons.email,
                      'Email с медиа файлами',
                    ),
                    _buildActionItem(
                      Icons.location_on,
                      'Ваше местоположение',
                    ),
                    if (_isRecording || _audioService.recordingPath != null)
                      _buildActionItem(
                        Icons.mic,
                        'Аудиозапись (${_recordingSeconds}с)',
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