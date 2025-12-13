import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/providers/auth_provider.dart';
import 'package:alertme/providers/contact_provider.dart';
import 'package:alertme/providers/language_provider.dart';
import 'package:alertme/models/emergency_contact.dart';
import 'package:alertme/models/user.dart';
import 'package:alertme/widgets/contact_card.dart';
import 'package:alertme/screens/add_contact_screen.dart';
import 'package:alertme/screens/subscription_screen.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final contactProvider = Provider.of<ContactProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) return const SizedBox();

    final canAdd = contactProvider.canAddContact(user);
    final limit = contactProvider.getContactLimit(user);

    return Scaffold(
      appBar: AppBar(title: Text(lang.translate('emergency_contacts'))),
      body: contactProvider.contacts.isEmpty
        ? _buildEmptyState(context, lang)
        : ListView.separated(
            padding: AppSpacing.paddingLg,
            itemCount: contactProvider.contacts.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final contact = contactProvider.contacts[index];
              return ContactCard(
                contact: contact,
                onDelete: () => _deleteContact(context, contact),
              );
            },
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (canAdd) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddContactScreen()),
            );
          } else {
            _showUpgradeDialog(context, lang, user);
          }
        },
        icon: const Icon(Icons.add),
        label: Text(lang.translate('add_contact')),
        backgroundColor: AppColors.deepBlue,
        foregroundColor: Colors.white,
      ),
      bottomSheet: !canAdd
        ? Container(
            width: double.infinity,
            padding: AppSpacing.paddingMd,
            color: AppColors.softCyan.withValues(alpha: 0.1),
            child: Text(
              '${lang.translate('contact_limit_reached')}: $limit',
              style: context.textStyles.bodyMedium?.withColor(AppColors.deepBlue),
              textAlign: TextAlign.center,
            ),
          )
        : null,
    );
  }

  Widget _buildEmptyState(BuildContext context, LanguageProvider lang) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              lang.translate('no_contacts'),
              style: context.textStyles.headlineSmall?.semiBold,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              lang.translate('add_first_contact'),
              style: context.textStyles.bodyMedium?.withColor(AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _deleteContact(BuildContext context, EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить контакт?'),
        content: Text('Вы уверены, что хотите удалить ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              context.read<ContactProvider>().deleteContact(contact.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.sosRed),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context, LanguageProvider lang, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('contact_limit_reached')),
        content: Text(lang.translate('upgrade_for_more')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
            child: Text(lang.translate('upgrade_to_premium')),
          ),
        ],
      ),
    );
  }
}
