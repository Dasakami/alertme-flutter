import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/providers/auth_provider.dart';
import 'package:alertme/providers/language_provider.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _telegramController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _firstNameController.text = user.firstName ?? '';
      _lastNameController.text = user.lastName ?? '';
      _emailController.text = user.email ?? '';
      _telegramController.text = user.telegramUsername ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _telegramController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final lang = context.read<LanguageProvider>();
    
    try {
      await authProvider.updateProfile(
        firstName: _firstNameController.text.isEmpty ? null : _firstNameController.text,
        lastName: _lastNameController.text.isEmpty ? null : _lastNameController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        telegramUsername: _telegramController.text.isEmpty ? null : _telegramController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.translate('profile_updated')),
            backgroundColor: AppColors.softCyan,
          ),
        );
      }
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(lang.translate('edit_profile'))),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: lang.translate('first_name'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: lang.translate('last_name'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: lang.translate('email_optional'),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              TextFormField(
                controller: _telegramController,
                decoration: InputDecoration(
                  labelText: lang.translate('telegram_username'),
                  hintText: 'username',
                  helperText: lang.translate('telegram_hint'),
                  prefixIcon: const Icon(Icons.alternate_email),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                ],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (value.length < 5) {
                      return lang.translate('min_5_chars');
                    }
                    if (value.startsWith('@')) {
                      return lang.translate('no_at_symbol');
                    }
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: AppColors.softCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.softCyan),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.softCyan, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          lang.translate('telegram_how_it_works'),
                          style: context.textStyles.labelLarge?.semiBold.withColor(AppColors.deepBlue),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '1. ${lang.translate('telegram_step_1')}\n'
                      '2. ${lang.translate('telegram_step_2')}\n'
                      '3. ${lang.translate('telegram_step_3')}\n'
                      '4. ${lang.translate('telegram_step_4')}',
                      style: context.textStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _save,
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(lang.translate('save')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}