import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/providers/auth_provider.dart';
import 'package:alertme/providers/language_provider.dart';
import 'package:alertme/screens/otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _password2Controller = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _password2Controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final lang = context.read<LanguageProvider>();
    
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim().isEmpty 
        ? null 
        : _emailController.text.trim();
    final pass = _passwordController.text;
    final pass2 = _password2Controller.text;

    try {
      final ok = await auth.register(
        phoneNumber: phone,
        password: pass,
        passwordConfirm: pass2,
        email: email,
        language: lang.currentLanguage,
      );

      if (!mounted) return;

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error ?? lang.translate('registration_error')),
            backgroundColor: AppColors.sosRed,
          ),
        );
        return;
      }

      final sent = await auth.sendOTP(phone);
      if (!mounted) return;

      if (!sent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error ?? lang.translate('sms_error')),
            backgroundColor: AppColors.sosRed,
          ),
        );
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OTPVerificationScreen(
            phoneNumber: phone,
            postVerifyPassword: pass,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = lang.translate('unknown_error');
      
      if (e.toString().contains('phone') || e.toString().contains('номер')) {
        errorMessage = lang.translate('invalid_phone');
      } else if (e.toString().contains('password') || e.toString().contains('пароль')) {
        errorMessage = lang.translate('password_error');
      } else if (e.toString().contains('email') || e.toString().contains('почта')) {
        errorMessage = lang.translate('invalid_email');
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = lang.translate('network_error');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMessage'),
          backgroundColor: AppColors.sosRed,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(lang.translate('create_account'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingXl,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                
                Text(
                  lang.translate('create_account'),
                  style: context.textStyles.displaySmall?.semiBold,
                ),
                
                const SizedBox(height: AppSpacing.xxl),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: lang.translate('phone_number'),
                    hintText: '+996555123456',
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Введите номер телефона';
                    }
                    if (!v.startsWith('+')) {
                      return 'Номер должен начинаться с +';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (необязательно)',
                    hintText: 'your@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: lang.translate('password'),
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure1 ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                    ),
                  ),
                  obscureText: _obscure1,
                  validator: (v) {
                    if (v == null || v.length < 6) {
                      return 'Минимум 6 символов';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _password2Controller,
                  decoration: InputDecoration(
                    labelText: lang.translate('confirm_password'),
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure2 ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                    ),
                  ),
                  obscureText: _obscure2,
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return 'Пароли не совпадают';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _submit,
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(lang.translate('continue')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
