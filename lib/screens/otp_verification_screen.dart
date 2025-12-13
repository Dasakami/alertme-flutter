import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/providers/auth_provider.dart';
import 'package:alertme/providers/language_provider.dart';
import 'package:alertme/screens/home_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  // Optional: password to perform automatic login after verification
  final String? postVerifyPassword;

  const OTPVerificationScreen({super.key, required this.phoneNumber, this.postVerifyPassword});

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

  void _verifyOTP() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length != 6) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOTP(widget.phoneNumber, otp);

    if (success && mounted) {
      // If password supplied, auto-login to obtain tokens
      if (widget.postVerifyPassword != null) {
        final ok = await authProvider.login(phoneNumber: widget.phoneNumber, password: widget.postVerifyPassword!);
        if (!mounted) return;
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authProvider.error ?? 'Не удалось войти после верификации'), backgroundColor: AppColors.sosRed),
          );
          return;
        }
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Ошибка верификации'),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Icon(Icons.lock_outline, size: 64, color: AppColors.deepBlue),
              const SizedBox(height: AppSpacing.xl),
              Text(lang.translate('verify_code'), style: context.textStyles.displaySmall?.semiBold),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${lang.translate('verification_sent')} ${widget.phoneNumber}',
                style: context.textStyles.bodyLarge?.withColor(AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '',
                style: context.textStyles.bodyMedium?.withColor(AppColors.deepBlue).semiBold,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) => _buildOTPField(index)),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _verifyOTP,
                  child: authProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
