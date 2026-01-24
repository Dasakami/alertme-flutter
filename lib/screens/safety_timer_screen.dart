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
import 'package:alertme/services/audio_service.dart';
import 'package:alertme/screens/sos_active_screen.dart';

class SafetyTimerScreen extends StatefulWidget {
  const SafetyTimerScreen({super.key});

  @override
  State<SafetyTimerScreen> createState() => _SafetyTimerScreenState();
}

class _SafetyTimerScreenState extends State<SafetyTimerScreen> {
  final TimerService _timerService = TimerService();
  final LocationService _locationService = LocationService();
  final AudioService _audioService = AudioService();
  
  int _selectedMinutes = 30;
  int _selectedSeconds = 0; // Для коротких тестов
  Timer? _countdownTimer;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _loadTimer();
    _audioService.init();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _recordingTimer?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _loadTimer() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null) {
      await _timerService.loadTimer(authProvider.currentUser!.id.toString());
      if (_timerService.hasActiveTimer) {
        _startCountdown();
        // Если таймер активен, начинаем запись
        _startRecording();
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

  // 🎤 НОВАЯ ЛОГИКА: Запись аудио во время таймера
  Future<void> _startRecording() async {
    final success = await _audioService.startRecording();
    
    if (success) {
      setState(() => _isRecording = true);
      
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() => _recordingSeconds++);
        }
      });
      
      debugPrint('🎤 Запись аудио начата для таймера');
    }
  }

  Future<String?> _stopRecording() async {
    _recordingTimer?.cancel();
    setState(() => _isRecording = false);
    
    final audioPath = await _audioService.stopRecording();
    debugPrint('🎤 Запись остановлена: $audioPath');
    
    return audioPath;
  }

  Future<void> _onTimerExpired() async {
    final contactProvider = context.read<ContactProvider>();
    final sosProvider = context.read<SOSProvider>();
    final lang = context.read<LanguageProvider>();

    if (contactProvider.contacts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.isRussian 
              ? 'Нет контактов для отправки SOS'
              : 'SOS жөнөтүү үчүн байланыштар жок'),
            backgroundColor: AppColors.sosRed,
          ),
        );
      }
      return;
    }

    // Останавливаем запись и получаем аудио
    String? audioPath;
    if (_isRecording) {
      audioPath = await _stopRecording();
    }

    await _timerService.completeTimer();
    
    try {
      final location = await _locationService.getCurrentLocation();
      
      if (location == null) {
        if (mounted) {
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

      // Отправляем SOS С АУДИО
      final alert = await sosProvider.triggerSOS(
        latitude: location.latitude,
        longitude: location.longitude,
        address: location.address,
        activationMethod: 'timer',
        notes: lang.isRussian 
          ? 'Таймер безопасности истек. Аудио: ${_recordingSeconds}с'
          : 'Коопсуздук таймери бүттү. Аудио: ${_recordingSeconds}с',
        audioPath: audioPath, // АУДИО ПРИКРЕПЛЕНО
      );

      if (alert != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SOSActiveScreen()),
        );
      }
    } catch (e) {
      debugPrint('❌ Ошибка активации SOS по таймеру: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${lang.translate('error')}: $e'),
            backgroundColor: AppColors.sosRed,
          ),
        );
      }
    }
  }

  Future<void> _startTimer() async {
    final authProvider = context.read<AuthProvider>();
    final lang = context.read<LanguageProvider>();
    
    if (authProvider.currentUser == null) return;

    // Определяем длительность (может быть в секундах для тестов)
    Duration duration;
    if (_selectedMinutes == 0) {
      // Это секунды (например, 30 секунд)
      duration = Duration(seconds: _selectedSeconds);
    } else {
      duration = Duration(minutes: _selectedMinutes);
    }

    await _timerService.startTimer(
      authProvider.currentUser!.id.toString(),
      duration,
    );
    
    _startCountdown();
    await _startRecording(); // Начинаем запись сразу
    
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(lang.isRussian 
          ? '🎤 Таймер запущен. Идет запись аудио...'
          : '🎤 Таймер башталды. Аудио жазылууда...'),
        backgroundColor: AppColors.deepBlue,
      ),
    );
  }

  Future<void> _cancelTimer() async {
    final lang = context.read<LanguageProvider>();
    
    if (_isRecording) {
      await _audioService.cancelRecording();
      _recordingTimer?.cancel();
      setState(() {
        _isRecording = false;
        _recordingSeconds = 0;
      });
    }
    
    await _timerService.cancelTimer();
    _countdownTimer?.cancel();
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(lang.isRussian 
          ? 'Таймер отменен. Запись удалена.'
          : 'Таймер жокко чыгарылды. Жазуу өчүрүлдү.'),
      ),
    );
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
            lang.isRussian
              ? 'Таймер безопасности автоматически активирует SOS в случае, если вы не сможете его отменить. Во время работы таймера ведется запись аудио для передачи в экстренные службы.'
              : 'Коопсуздук таймери сиз аны жокко чыгара албасаңыз, автоматтык түрдө SOS активдештирет. Таймер иштегенде аудио жазуу жүргүзүлөт жана ал өзгөчө кырдаалдар кызматтарына жөнөтүлөт.',
            style: context.textStyles.bodyMedium?.withColor(AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        
        // Быстрые таймеры
        _buildTimerCategory(
          lang.isRussian ? 'Быстрые' : 'Тез',
          [
            _TimerOption(label: '3 ${lang.translate('seconds')}', seconds: 3),
            _TimerOption(label: '30 ${lang.translate('seconds')}', seconds: 30),
            _TimerOption(label: '1 ${lang.translate('minutes')}', minutes: 1),
          ]
        ),
        
        const SizedBox(height: AppSpacing.sm),
        
        _buildTimerCategory(
          lang.isRussian ? 'Стандартные' : 'Стандарттык',
          [
            _TimerOption(label: '5 ${lang.translate('minutes')}', minutes: 5),
            _TimerOption(label: '10 ${lang.translate('minutes')}', minutes: 10),
            _TimerOption(label: '15 ${lang.translate('minutes')}', minutes: 15),
            _TimerOption(label: '30 ${lang.translate('minutes')}', minutes: 30),
          ]
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        Container(
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: AppColors.softCyan.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.softCyan),
          ),
          child: Row(
            children: [
              const Icon(Icons.mic, color: AppColors.deepBlue, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  lang.isRussian 
                    ? 'Аудио запись начнется сразу после запуска таймера'
                    : 'Аудио жазуу таймер башталгандан кийин дароо башталат',
                  style: context.textStyles.bodySmall?.semiBold.withColor(AppColors.deepBlue),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _startTimer,
            child: Text(lang.isRussian 
              ? 'Запустить таймер с записью'
              : 'Жазуу менен таймерди баштоо'),
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
            final isSelected = (option.minutes > 0 && _selectedMinutes == option.minutes && _selectedSeconds == 0) ||
                               (option.seconds > 0 && _selectedSeconds == option.seconds && _selectedMinutes == 0);
            
            return ChoiceChip(
              label: Text(option.label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (option.seconds > 0) {
                    _selectedSeconds = option.seconds;
                    _selectedMinutes = 0;
                  } else {
                    _selectedMinutes = option.minutes;
                    _selectedSeconds = 0;
                  }
                });
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
            decoration: const BoxDecoration(
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
        
        // Показываем статус записи
        if (_isRecording)
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: AppColors.sosRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.sosRed),
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
                  '${lang.isRussian ? 'Запись' : 'Жазылууда'}: ${_recordingSeconds}${lang.translate('seconds')}',
                  style: context.textStyles.bodyMedium?.semiBold.withColor(AppColors.sosRed),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: AppSpacing.lg),
        
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
                      lang.isRussian 
                        ? 'SOS с аудио будет отправлен через $seconds секунд!'
                        : 'Аудио менен SOS $seconds секундадан кийин жөнөтүлөт!',
                      style: context.textStyles.bodyMedium?.semiBold.withColor(AppColors.sosRed),
                    ),
                  ),
                ],
              ),
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