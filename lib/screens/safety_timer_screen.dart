import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/providers/auth_provider.dart';
import 'package:alertme/providers/contact_provider.dart';
import 'package:alertme/providers/sos_provider.dart';
import 'package:alertme/providers/language_provider.dart';
import 'package:alertme/services/timer_service.dart';
import 'package:alertme/services/location_service.dart'; // ДОБАВЛЕНО
import 'package:alertme/screens/sos_active_screen.dart';

class SafetyTimerScreen extends StatefulWidget {
  const SafetyTimerScreen({super.key});

  @override
  State<SafetyTimerScreen> createState() => _SafetyTimerScreenState();
}

class _SafetyTimerScreenState extends State<SafetyTimerScreen> {
  final TimerService _timerService = TimerService();
  final LocationService _locationService = LocationService(); // ДОБАВЛЕНО
  int _selectedMinutes = 30;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTimer() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null) {
      await _timerService.loadTimer(authProvider.currentUser!.id.toString()); // ИСПРАВЛЕНО: добавлен .toString()
      if (_timerService.hasActiveTimer) {
        _startCountdown();
      }
      setState(() {});
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
        if (_timerService.activeTimer?.isExpired ?? false) {
          timer.cancel();
          _onTimerExpired();
        }
      }
    });
  }

  Future<void> _onTimerExpired() async {
    final contactProvider = context.read<ContactProvider>();
    final sosProvider = context.read<SOSProvider>();

    if (contactProvider.contacts.isEmpty) return;

    await _timerService.completeTimer();
    
    // ИСПРАВЛЕНО: получаем местоположение и передаем параметры
    final location = await _locationService.getCurrentLocation();
    
    if (location == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось определить местоположение'),
            backgroundColor: AppColors.sosRed,
          ),
        );
      }
      return;
    }

    final alert = await sosProvider.triggerSOS(
      latitude: location.latitude,
      longitude: location.longitude,
      address: location.address,
      activationMethod: 'timer',
      notes: 'Таймер безопасности истек',
    );

    if (alert != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SOSActiveScreen()),
      );
    }
  }

  void _startTimer() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser == null) return;

    await _timerService.startTimer(
      authProvider.currentUser!.id.toString(), // ИСПРАВЛЕНО: добавлен .toString()
      Duration(minutes: _selectedMinutes),
    );
    
    _startCountdown();
    setState(() {});
  }

  void _cancelTimer() async {
    await _timerService.cancelTimer();
    _countdownTimer?.cancel();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final hasActiveTimer = _timerService.hasActiveTimer;
    final activeTimer = _timerService.activeTimer;

    return Scaffold(
      appBar: AppBar(title: Text(lang.translate('safety_timer'))),
      body: Padding(
        padding: AppSpacing.paddingXl,
        child: hasActiveTimer && activeTimer != null
          ? _buildActiveTimer(context, lang, activeTimer.remainingTime)
          : _buildTimerSetup(context, lang),
      ),
    );
  }

  Widget _buildTimerSetup(BuildContext context, LanguageProvider lang) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.timer_outlined, size: 80, color: AppColors.deepBlue),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          lang.translate('set_timer'),
          style: context.textStyles.headlineMedium?.semiBold,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Если вы не отменить таймер, автоматически отправится SOS',
          style: context.textStyles.bodyMedium?.withColor(AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          alignment: WrapAlignment.center,
          children: [15, 30, 45, 60, 90, 120].map((minutes) {
            final isSelected = _selectedMinutes == minutes;
            return ChoiceChip(
              label: Text('$minutes ${lang.translate('minutes')}'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedMinutes = minutes);
              },
              selectedColor: AppColors.deepBlue,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.xxl),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _startTimer,
            child: Text('Запустить таймер'),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTimer(BuildContext context, LanguageProvider lang, Duration remaining) {
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.softCyan.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.softCyan, width: 3),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: context.textStyles.displayLarge?.semiBold.withColor(AppColors.deepBlue),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  lang.translate('timer_active'),
                  style: context.textStyles.bodyMedium?.withColor(AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Таймер истечёт через ${minutes}м ${seconds}с',
          style: context.textStyles.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _cancelTimer,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.sosRed, width: 1.5),
              foregroundColor: AppColors.sosRed,
            ),
            child: Text(lang.translate('cancel')),
          ),
        ),
      ],
    );
  }
}
