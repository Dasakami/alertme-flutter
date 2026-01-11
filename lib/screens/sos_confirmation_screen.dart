import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/providers/contact_provider.dart';
import 'package:alertme/providers/sos_provider.dart';
import 'package:alertme/providers/language_provider.dart';
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

  Future<void> _activateSOS(BuildContext context) async {
    final sosProvider = context.read<SOSProvider>();
    final locationService = LocationService();
    final lang = context.read<LanguageProvider>();

    String? audioPath;
    if (_isRecording) {
      audioPath = await _audioService.stopRecording();
    } else {
      audioPath = _audioService.recordingPath;
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final location = await locationService.getCurrentLocation();
      
      if (location == null) {
        if (context.mounted) {
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

      final alert = await sosProvider.triggerSOS(
        latitude: location.latitude,
        longitude: location.longitude,
        address: location.address,
        activationMethod: 'button',
        notes: audioPath != null ? (lang.isRussian ? 'С аудиозаписью' : 'Аудио менен') : null,
        audioPath: audioPath,
      );

      if (alert == null) {
        if (context.mounted) {
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

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pop(context); 
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
            content: Text('${lang.translate('error')}: $e'),
            backgroundColor: AppColors.sosRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactProvider = context.watch<ContactProvider>();
    final lang = context.watch<LanguageProvider>();
    
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
                lang.translate('activate_sos_question'),
                style: context.textStyles.displaySmall?.semiBold
                    .withColor(Colors.white),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
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
                        '${lang.translate('recording_audio')}: ${_recordingSeconds}${lang.translate('seconds')} / 30${lang.translate('seconds')}',
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
                      lang.translate('will_be_sent'),
                      style: context.textStyles.bodyLarge?.semiBold
                          .withColor(Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildActionItem(
                      Icons.sms,
                      '${lang.translate('sms_to_contacts')} (${contactProvider.contacts.length})',
                    ),
                    _buildActionItem(
                      Icons.email,
                      lang.translate('email_with_media'),
                    ),
                    _buildActionItem(
                      Icons.location_on,
                      lang.translate('your_location'),
                    ),
                    if (_isRecording || _audioService.recordingPath != null)
                      _buildActionItem(
                        Icons.mic,
                        '${lang.translate('audio_recording')} (${_recordingSeconds}${lang.translate('seconds')})',
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
                        child: Text(lang.translate('cancel')),
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
                        child: Text(lang.translate('activate')),
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