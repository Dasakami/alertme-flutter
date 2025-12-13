import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/providers/auth_provider.dart';
import 'package:alertme/providers/language_provider.dart';
import 'package:alertme/screens/home_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String? postVerifyPassword;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.postVerifyPassword,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length != 6) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOTP(widget.phoneNumber, otp);

    if (!mounted) return;

    if (success) {
      // Если есть пароль - делаем автоматический вход
      if (widget.postVerifyPassword != null) {
        final ok = await authProvider.login(
          phoneNumber: widget.phoneNumber,
          password: widget.postVerifyPassword!,
        );
        if (!mounted) return;
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? 'Не удалось войти'),
              backgroundColor: AppColors.sosRed,
            ),
          );
          return;
        }
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Неверный код'),
          backgroundColor: AppColors.sosRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingXl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: AppColors.deepBlue,
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              Text(
                lang.translate('verify_code'),
                style: context.textStyles.displaySmall?.semiBold,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              Text(
                '${lang.translate('verification_sent')} ${widget.phoneNumber}',
                style: context.textStyles.bodyLarge?.withColor(AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Поля для кода
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) => _buildOTPField(index)),
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Кнопка подтверждения
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _verifyOTP,
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(lang.translate('verify')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOTPField(int index) {
    return SizedBox(
      width: 48,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: context.textStyles.headlineMedium?.semiBold,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
              _verifyOTP();
            }
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}