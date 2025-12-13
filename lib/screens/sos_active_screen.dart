import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/providers/sos_provider.dart';
import 'package:alertme/providers/language_provider.dart';

class SOSActiveScreen extends StatefulWidget {
  const SOSActiveScreen({super.key});

  @override
  State<SOSActiveScreen> createState() => _SOSActiveScreenState();
}

class _SOSActiveScreenState extends State<SOSActiveScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _cancelSOS() async {
    final sosProvider = context.read<SOSProvider>();
    await sosProvider.cancelSOS();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final sosProvider = Provider.of<SOSProvider>(context);
    final activeAlert = sosProvider.activeAlert; // ИСПРАВЛЕНО: activeEvent -> activeAlert

    return Scaffold(
      backgroundColor: AppColors.sosRed,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.paddingXl,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Анимированная иконка
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _pulseAnimation.value,
                  child: child,
                ),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_rounded, size: 100, color: Colors.white),
                ),
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Заголовок
              Text(
                lang.translate('sos_activated'),
                style: context.textStyles.displaySmall?.semiBold.withColor(Colors.white),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Статус
              Text(
                lang.translate('sending_alert'),
                style: context.textStyles.bodyLarge?.withColor(Colors.white.withValues(alpha: 0.9)),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Индикатор записи
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mic, color: Colors.white, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      lang.translate('recording_audio'),
                      style: context.textStyles.bodyMedium?.withColor(Colors.white),
                    ),
                  ],
                ),
              ),
              
              // Местоположение
              if (activeAlert?.latitude != null && activeAlert?.longitude != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, color: Colors.white, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          activeAlert?.address ?? 'Местоположение отправлено',
                          style: context.textStyles.bodyMedium?.withColor(Colors.white),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Список уведомлений
              if (activeAlert?.notifications.isNotEmpty ?? false) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications, color: Colors.white, size: 20),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Уведомлено контактов: ${activeAlert!.notifications.length}',
                        style: context.textStyles.bodyMedium?.withColor(Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
              
              const Spacer(),
              
              // Кнопка отмены
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _cancelSOS,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.sosRed,
                  ),
                  child: Text(lang.translate('cancel')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}