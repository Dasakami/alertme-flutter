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
  bool _phoneGranted = false;
  bool _smsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final location = await Permission.location.status;
    final microphone = await Permission.microphone.status;
    final phone = await Permission.phone.status;
    final sms = await Permission.sms.status;

    setState(() {
      _locationGranted = location.isGranted;
      _microphoneGranted = microphone.isGranted;
      _phoneGranted = phone.isGranted;
      _smsGranted = sms.isGranted;
    });
  }

  Future<void> _requestAllPermissions() async {
    final statuses = await [
      Permission.location,
      Permission.microphone,
      Permission.phone,
      Permission.sms,
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
    final isMobileSize = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: AppSpacing.paddingXl,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: isMobileSize ? 80 : 100,
                    height: isMobileSize ? 80 : 100,
                    decoration: BoxDecoration(
                      color: AppColors.deepBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.security,
                      size: isMobileSize ? 40 : 48,
                      color: AppColors.deepBlue,
                    ),
                  ),

                  SizedBox(height: isMobileSize ? AppSpacing.lg : AppSpacing.xxl),

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

                  SizedBox(height: isMobileSize ? AppSpacing.lg : AppSpacing.xxl),
                  _buildPermissionItem(
                    icon: Icons.location_on,
                    title: 'Местоположение',
                    description: 'Для отправки вашего местоположения при SOS',
                    granted: _locationGranted,
                    required: true,
                  ),

                  _buildPermissionItem(
                    icon: Icons.mic,
                    title: 'Микрофон',
                    description: 'Для записи аудио при активации SOS',
                    granted: _microphoneGranted,
                    required: true,
                  ),

                  _buildPermissionItem(
                    icon: Icons.phone,
                    title: 'Телефон',
                    description: 'Для звонков экстренным контактам',
                    granted: _phoneGranted,
                    required: false,
                  ),

                  _buildPermissionItem(
                    icon: Icons.sms,
                    title: 'SMS',
                    description: 'Для отправки SMS уведомлений',
                    granted: _smsGranted,
                    required: false,
                  ),

                  SizedBox(height: isMobileSize ? AppSpacing.lg : AppSpacing.xxl),
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
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool granted,
    required bool required,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                  Wrap(
                    spacing: AppSpacing.xs,
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: context.textStyles.bodyLarge?.semiBold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (required)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.sosRed.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Обязательно',
                            style: context.textStyles.labelSmall?.withColor(
                              AppColors.sosRed,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: context.textStyles.bodySmall?.withColor(
                      AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
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