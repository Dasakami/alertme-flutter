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
    final email = _emailController.text.trim().isEmpty ? null : _emailController.text.trim();
    final pass = _passwordController.text;
    final pass2 = _password2Controller.text;

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
        SnackBar(content: Text(auth.error ?? 'Ошибка регистрации'), backgroundColor: AppColors.sosRed),
      );
      return;
    }

    // Send SMS
    final sent = await auth.sendOTP(phone);
    if (!mounted) return;
    if (!sent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Не удалось отправить SMS'), backgroundColor: AppColors.sosRed),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OTPVerificationScreen(phoneNumber: phone, postVerifyPassword: pass),
      ),
    );
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                Text(lang.translate('create_account'), style: context.textStyles.displaySmall?.semiBold),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(hintText: '+996555123456', labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите номер' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(hintText: 'you@email.com', labelText: 'Email (optional)'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    labelText: lang.translate('password'),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure1 ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                    ),
                  ),
                  obscureText: _obscure1,
                  validator: (v) => (v == null || v.length < 6) ? 'Минимум 6 символов' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _password2Controller,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    labelText: lang.translate('confirm_password'),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure2 ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                    ),
                  ),
                  obscureText: _obscure2,
                  validator: (v) => (v != _passwordController.text) ? 'Пароли не совпадают' : null,
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _submit,
                    child: auth.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
