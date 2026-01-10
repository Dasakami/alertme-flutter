import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/providers/contact_provider.dart';
import 'package:alertme/providers/language_provider.dart';
import 'package:alertme/models/emergency_contact.dart';
import 'package:alertme/services/api_client.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _relationController = TextEditingController();
  final _telegramController = TextEditingController();
  bool _isPrimary = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _relationController.dispose();
    _telegramController.dispose();
    super.dispose();
  }

  /// ✅ УЛУЧШЕНО: Обработка всех ошибок
  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final contact = EmergencyContact(
      id: 0,
      name: _nameController.text,
      phoneNumber: '+996${_phoneController.text}',
      email: _emailController.text.isEmpty ? null : _emailController.text,
      relation: _relationController.text.isEmpty ? null : _relationController.text,
      telegramUsername: _telegramController.text.isEmpty ? null : _telegramController.text,
      isPrimary: _isPrimary,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final contactProvider = context.read<ContactProvider>();
      await contactProvider.addContact(contact);

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Контакт добавлен'),
          backgroundColor: AppColors.softCyan,
          duration: Duration(seconds: 2),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      
      // ✅ Показываем понятное сообщение об ошибке
      String errorMessage = e.message;
      
      // Переводим распространенные ошибки
      if (e.message.toLowerCase().contains('unique') || 
          e.message.toLowerCase().contains('duplicate')) {
        errorMessage = 'Контакт с таким номером уже добавлен';
      } else if (e.message.toLowerCase().contains('maximum') || 
                 e.message.toLowerCase().contains('limit')) {
        errorMessage = 'Достигнут лимит контактов';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMessage'),
          backgroundColor: AppColors.sosRed,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'ОК',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ошибка: ${e.toString()}'),
          backgroundColor: AppColors.sosRed,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(lang.translate('add_contact'))),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Имя
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: lang.translate('name'),
                  hintText: 'Иван Иванов',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите имя';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Телефон
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderLight),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: Text('+996', style: context.textStyles.bodyLarge),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9),
                      ],
                      decoration: InputDecoration(
                        labelText: lang.translate('phone_number'),
                        hintText: '555 123 456',
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите номер';
                        }
                        if (value.length != 9) {
                          return 'Неверный формат';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Telegram Username
              TextFormField(
                controller: _telegramController,
                decoration: InputDecoration(
                  labelText: 'Telegram Username (необязательно)',
                  hintText: 'username',
                  helperText: 'Без @. Для SOS уведомлений',
                  prefixIcon: const Icon(Icons.alternate_email),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                ],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (value.length < 5) {
                      return 'Минимум 5 символов';
                    }
                    if (value.startsWith('@')) {
                      return 'Не указывайте @';
                    }
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (необязательно)',
                  hintText: 'ivan@example.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Отношение
              TextFormField(
                controller: _relationController,
                decoration: const InputDecoration(
                  labelText: 'Отношение (необязательно)',
                  hintText: 'Друг, Родственник, Коллега',
                  prefixIcon: Icon(Icons.favorite_outline),
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Основной контакт
              CheckboxListTile(
                value: _isPrimary,
                onChanged: (value) => setState(() => _isPrimary = value ?? false),
                title: const Text('Основной контакт'),
                subtitle: const Text('Будет получать уведомления первым'),
                contentPadding: EdgeInsets.zero,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Информация о Telegram
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: AppColors.softCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.softCyan),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.softCyan, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Если у контакта есть Telegram, SOS уведомления придут туда',
                        style: context.textStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Кнопка сохранения
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveContact,
                  child: _isLoading
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