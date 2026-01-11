import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/providers/auth_provider.dart';
import 'package:alertme/providers/contact_provider.dart';
import 'package:alertme/providers/sos_provider.dart';
import 'package:alertme/providers/language_provider.dart';
import 'package:alertme/services/timer_service.dart';
import 'package:alertme/services/location_service.dart';
import 'package:alertme/screens/sos_active_screen.dart';

class SafetyTimerScreen extends StatefulWidget {
  const SafetyTimerScreen({super.key});

  @override
  State<SafetyTimerScreen> createState() => _SafetyTimerScreenState();
}

class _SafetyTimerScreenState extends State<SafetyTimerScreen> {
  final TimerService _timerService = TimerService();
  final LocationService _locationService = LocationService();
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
      await _timerService.loadTimer(authProvider.currentUser!.id.toString());
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

    if (contactProvider.contacts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Нет контактов для отправки SOS'),
            backgroundColor: AppColors.sosRed,
          ),
        );
      }
      return;
    }

    await _timerService.completeTimer();
    
    try {
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
          MaterialPageRoute(builder: (_) => SOSActiveScreen()),
        );
      }
    } catch (e) {
      debugPrint('❌ Ошибка активации SOS по таймеру: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка активации SOS: $e'),
            backgroundColor: AppColors.sosRed,
          ),
        );
      }
    }
  }

  void _startTimer() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser == null) return;

    await _timerService.startTimer(
      authProvider.currentUser!.id.toString(),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: hasActiveTimer && activeTimer != null
            ? _buildActiveTimer(context, lang, activeTimer.remainingTime)
            : _buildTimerSetup(context, lang),
        ),
      ),
    );
  }

  Widget _buildTimerSetup(BuildContext context, LanguageProvider lang) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.md),
        Icon(Icons.timer_outlined, size: 64, color: AppColors.deepBlue),
        const SizedBox(height: AppSpacing.lg),
        Text(
          lang.translate('set_timer'),
          style: context.textStyles.headlineSmall?.semiBold,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            lang.translate('timer_description'),
            style: context.textStyles.bodyMedium?.withColor(AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        
        _buildTimerCategory(lang.translate('quick_tests'), [
          _TimerOption(label: '3 ${lang.translate('seconds')}', seconds: 3),
          _TimerOption(label: '5 ${lang.translate('minutes')}', minutes: 5),
        ]),
        
        const SizedBox(height: AppSpacing.sm),
        
        _buildTimerCategory(lang.translate('standard'), [
          _TimerOption(label: '15 ${lang.translate('minutes')}', minutes: 15),
          _TimerOption(label: '30 ${lang.translate('minutes')}', minutes: 30),
          _TimerOption(label: '45 ${lang.translate('minutes')}', minutes: 45),
          _TimerOption(label: '1 ${lang.translate('hour')}', minutes: 60),
        ]),
        
        const SizedBox(height: AppSpacing.sm),
        
        _buildTimerCategory(lang.translate('long_timers'), [
          _TimerOption(label: '1.5 ${lang.translate('hours')}', minutes: 90),
          _TimerOption(label: '2 ${lang.translate('hours')}', minutes: 120),
        ]),
        
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _startTimer,
            child: Text(lang.translate('start_timer')),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildTimerCategory(String title, List<_TimerOption> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            title,
            style: context.textStyles.labelMedium?.semiBold.withColor(AppColors.deepBlue),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.start,
          children: options.map((option) {
            final totalMinutes = option.getTotalMinutes();
            final isSelected = _selectedMinutes == totalMinutes;
            
            return ChoiceChip(
              label: Text(option.label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedMinutes = totalMinutes);
              },
              selectedColor: AppColors.deepBlue,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActiveTimer(BuildContext context, LanguageProvider lang, Duration remaining) {
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    final isShortTimer = remaining.inSeconds <= 10;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: (isShortTimer ? AppColors.sosRed : AppColors.softCyan).withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: isShortTimer ? AppColors.sosRed : AppColors.softCyan, 
              width: 4
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            margin: const EdgeInsets.all(8),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: context.textStyles.displayMedium?.semiBold.withColor(
                      isShortTimer ? AppColors.sosRed : AppColors.deepBlue
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    lang.translate('timer_active'),
                    style: context.textStyles.bodySmall?.withColor(AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: AppSpacing.xl),
        
        if (isShortTimer)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: AppColors.sosRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.sosRed),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning, color: AppColors.sosRed, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      lang.translate('time_warning'),
                      style: context.textStyles.bodyMedium?.semiBold.withColor(AppColors.sosRed),
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        if (!isShortTimer)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              '${lang.translate('time_remaining')} ${minutes}${lang.translate('minutes')} ${seconds}${lang.translate('seconds')}',
              style: context.textStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        
        const SizedBox(height: AppSpacing.xl),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: _cancelTimer,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.sosRed, width: 1.5),
                foregroundColor: AppColors.sosRed,
              ),
              child: Text(lang.translate('cancel')),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _TimerOption {
  final String label;
  final int minutes;
  final int seconds;

  _TimerOption({
    required this.label, 
    this.minutes = 0, 
    this.seconds = 0
  });

  int getTotalMinutes() {
    if (seconds > 0) {
      return seconds ~/ 60;
    }
    return minutes;
  }
}