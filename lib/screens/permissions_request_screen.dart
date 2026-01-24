import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/screens/login_screen.dart';

class PermissionsRequestScreen extends StatefulWidget {
  const PermissionsRequestScreen({super.key});

  @override
  State<PermissionsRequestScreen> createState() => _PermissionsRequestScreenState();
}

class _PermissionsRequestScreenState extends State<PermissionsRequestScreen> {
  bool _locationGranted = false;
  bool _microphoneGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final location = await Permission.location.status;
    final microphone = await Permission.microphone.status;

    setState(() {
      _locationGranted = location.isGranted;
      _microphoneGranted = microphone.isGranted;
    });
  }

  Future<void> _requestAllPermissions() async {
    final statuses = await [
      Permission.location,
      Permission.microphone,
    ].request();

    await _checkPermissions();
    
    if (_locationGranted && _microphoneGranted) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Необходимы разрешения'),
        content: const Text(
          'Для работы приложения необходимы разрешения на:\n\n'
          '• Местоположение - для отправки SOS\n'
          '• Микрофон - для записи аудио\n\n'
          'Без этих разрешений приложение не сможет работать корректно.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Открыть настройки'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: AppSpacing.paddingXl,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.deepBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.security,
                        size: 40,
                        color: AppColors.deepBlue,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    Text(
                      'Разрешения',
                      style: context.textStyles.displaySmall?.semiBold,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Text(
                      'Для работы приложения необходимы следующие разрешения:',
                      style: context.textStyles.bodyMedium?.withColor(
                        AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    _buildPermissionItem(
                      icon: Icons.location_on,
                      title: 'Местоположение',
                      description: 'Для отправки вашего местоположения при SOS',
                      granted: _locationGranted,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    _buildPermissionItem(
                      icon: Icons.mic,
                      title: 'Микрофон',
                      description: 'Для записи аудио при активации SOS',
                      granted: _microphoneGranted,
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _requestAllPermissions,
                        child: const Text('Предоставить разрешения'),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text('Пропустить'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool granted,
  }) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: granted
                    ? AppColors.softCyan.withValues(alpha: 0.2)
                    : AppColors.textSecondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: granted ? AppColors.softCyan : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.textStyles.bodyLarge?.semiBold,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: context.textStyles.bodySmall?.withColor(
                      AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              granted ? Icons.check_circle : Icons.circle_outlined,
              color: granted ? AppColors.softCyan : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}