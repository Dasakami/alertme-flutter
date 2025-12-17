// lib/screens/activation_code_screen.dart - ИСПРАВЛЕННАЯ ВЕРСИЯ
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/providers/subscription_provider.dart';
import 'package:alertme/providers/language_provider.dart';

class ActivationCodeScreen extends StatefulWidget {
  const ActivationCodeScreen({super.key});

  @override
  State<ActivationCodeScreen> createState() => _ActivationCodeScreenState();
}

class _ActivationCodeScreenState extends State<ActivationCodeScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _activateCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final subscriptionProvider = context.read<SubscriptionProvider>();
    final code = _codeController.text.trim().toUpperCase();

    try {
      final success = await subscriptionProvider.activateCode(code);

      if (!mounted) return;

      if (success) {
        // ✅ ОБНОВЛЯЕМ ПОДПИСКУ ПОСЛЕ АКТИВАЦИИ
        await subscriptionProvider.loadCurrentSubscription();
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Premium подписка активирована!'),
            backgroundColor: AppColors.softCyan,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(subscriptionProvider.error ?? 'Ошибка активации'),
            backgroundColor: AppColors.sosRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: AppColors.sosRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Активация кода'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingXl,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              
              // Иконка
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.deepBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.vpn_key,
                  size: 48,
                  color: AppColors.deepBlue,
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              Text(
                'Активация Premium',
                style: context.textStyles.displaySmall?.semiBold,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              Text(
                'Введите код из Telegram бота',
                style: context.textStyles.bodyLarge?.withColor(AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Поле для кода
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Код активации',
                  hintText: 'XXXX-XXXX-XXXX',
                  prefixIcon: Icon(Icons.vpn_key),
                ),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9-]')),
                  LengthLimitingTextInputFormatter(14),
                  _CodeInputFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите код';
                  }
                  if (value.replaceAll('-', '').length != 12) {
                    return 'Неверный формат кода';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Кнопка активации
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _activateCode,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Активировать'),
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Инструкция
              Container(
                padding: AppSpacing.paddingLg,
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
                        const Icon(Icons.info_outline, color: AppColors.softCyan),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Как получить код?',
                          style: context.textStyles.titleMedium?.semiBold
                              .withColor(AppColors.deepBlue),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildStep('1', 'Откройте Telegram'),
                    _buildStep('2', 'Найдите бот @AlertMePremiumBot'),
                    _buildStep('3', 'Оплатите подписку звездами'),
                    _buildStep('4', 'Скопируйте полученный код'),
                    _buildStep('5', 'Вставьте код в это поле'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.deepBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: context.textStyles.labelSmall?.semiBold
                    .withColor(Colors.white),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: context.textStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// Форматтер для автоматического добавления дефисов
class _CodeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('-', '').toUpperCase();
    
    if (text.length <= 4) {
      return newValue.copyWith(text: text);
    } else if (text.length <= 8) {
      return newValue.copyWith(
        text: '${text.substring(0, 4)}-${text.substring(4)}',
        selection: TextSelection.collapsed(offset: text.length + 1),
      );
    } else {
      return newValue.copyWith(
        text: '${text.substring(0, 4)}-${text.substring(4, 8)}-${text.substring(8, text.length > 12 ? 12 : text.length)}',
        selection: TextSelection.collapsed(
          offset: text.length > 12 ? 14 : (text.length + 2),
        ),
      );
    }
  }
}