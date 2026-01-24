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
  bool _isPrimary = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final lang = context.read<LanguageProvider>();
    final contact = EmergencyContact(
      id: 0,
      name: _nameController.text,
      phoneNumber: '+996${_phoneController.text}',
      email: _emailController.text.isEmpty ? null : _emailController.text,
      relation: _relationController.text.isEmpty ? null : _relationController.text,
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
        SnackBar(
          content: Text(lang.translate('contact_added')),
          backgroundColor: AppColors.softCyan,
          duration: const Duration(seconds: 2),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      
      String errorMessage = e.message;
      
      if (e.message.toLowerCase().contains('unique') || 
          e.message.toLowerCase().contains('duplicate')) {
        errorMessage = lang.translate('contact_exists');
      } else if (e.message.toLowerCase().contains('maximum') || 
                 e.message.toLowerCase().contains('limit')) {
        errorMessage = lang.translate('limit_reached');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMessage'),
          backgroundColor: AppColors.sosRed,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: lang.translate('ok'),
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
          content: Text('❌ ${lang.translate('error')}: ${e.toString()}'),
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
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: lang.translate('name'),
                  hintText: lang.isRussian ? 'Иван Иванов' : 'Асан Усенов',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return lang.translate('enter_name');
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppSpacing.lg),
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
                          return lang.translate('enter_number');
                        }
                        if (value.length != 9) {
                          return lang.translate('invalid_format');
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: lang.translate('email_optional'),
                  hintText: 'ivan@example.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _relationController,
                decoration: InputDecoration(
                  labelText: lang.translate('relation_optional'),
                  hintText: lang.translate('relation_hint'),
                  prefixIcon: const Icon(Icons.favorite_outline),
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              CheckboxListTile(
                value: _isPrimary,
                onChanged: (value) => setState(() => _isPrimary = value ?? false),
                title: Text(lang.translate('primary_contact')),
                subtitle: Text(lang.translate('primary_contact_desc')),
                contentPadding: EdgeInsets.zero,
              ),
              
              const SizedBox(height: AppSpacing.md),
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
                        lang.translate('telegram_info'),
                        style: context.textStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
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