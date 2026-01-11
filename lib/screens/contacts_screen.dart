import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/providers/auth_provider.dart';
import 'package:alertme/providers/contact_provider.dart';
import 'package:alertme/providers/subscription_provider.dart';
import 'package:alertme/providers/language_provider.dart';
import 'package:alertme/models/emergency_contact.dart';
import 'package:alertme/widgets/contact_card.dart';
import 'package:alertme/screens/add_contact_screen.dart';
import 'package:alertme/screens/subscription_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactProvider>().loadContacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final contactProvider = Provider.of<ContactProvider>(context);
    final authProvider = context.read<AuthProvider>();

    final maxContacts = authProvider.currentUser?.isPremium == true ? 999 : 3;
    final canAdd = contactProvider.canAddContact(maxContacts);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('emergency_contacts')),
        actions: [
          if (contactProvider.contacts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showInfo(context, lang, maxContacts),
            ),
        ],
      ),
      body: contactProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : contactProvider.contacts.isEmpty
              ? _buildEmptyState(context, lang)
              : RefreshIndicator(
                  onRefresh: () => context.read<ContactProvider>().loadContacts(),
                  child: ListView.separated(
                    padding: AppSpacing.paddingLg,
                    itemCount: contactProvider.contacts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final contact = contactProvider.contacts[index];
                      return ContactCard(
                        contact: contact,
                        onDelete: () => _deleteContact(context, lang, contact),
                        onSetPrimary: () => _setPrimary(context, lang, contact.id),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (canAdd) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddContactScreen()),
            );
          } else {
            _showUpgradeDialog(context, lang, maxContacts);
          }
        },
        icon: const Icon(Icons.add),
        label: Text(lang.translate('add_contact')),
        backgroundColor: canAdd ? AppColors.deepBlue : AppColors.textSecondary,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: !canAdd
          ? Container(
              padding: AppSpacing.paddingMd,
              color: AppColors.softCyan.withValues(alpha: 0.1),
              child: SafeArea(
                child: Text(
                  '${lang.translate('contact_limit_reached')}: ${contactProvider.contacts.length}/$maxContacts',
                  style: context.textStyles.bodyMedium?.semiBold.withColor(AppColors.deepBlue),
                  textAlign: TextAlign.center,
                ),
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
            Icon(
              Icons.people_outline,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
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

  void _deleteContact(BuildContext context, LanguageProvider lang, EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('delete_contact_question')),
        content: Text('${lang.translate('delete_contact_confirm')} ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await context.read<ContactProvider>().deleteContact(contact.id);
              if (context.mounted && !ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(lang.translate('delete_error')),
                    backgroundColor: AppColors.sosRed,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.sosRed),
            child: Text(lang.translate('delete')),
          ),
        ],
      ),
    );
  }

  void _setPrimary(BuildContext context, LanguageProvider lang, int contactId) async {
    final ok = await context.read<ContactProvider>().setPrimary(contactId);
    if (!context.mounted) return;
    
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.translate('primary_set')),
          backgroundColor: AppColors.softCyan,
        ),
      );
    }
  }

  void _showUpgradeDialog(BuildContext context, LanguageProvider lang, int limit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('contact_limit_reached')),
        content: Text('${lang.translate('total_contacts')}: $limit. ${lang.translate('upgrade_for_more')}'),
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

  void _showInfo(BuildContext context, LanguageProvider lang, int limit) {
    final contacts = context.read<ContactProvider>().contacts;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('information')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${lang.translate('total_contacts')} ${contacts.length}'),
            Text('${lang.translate('limit')} $limit'),
            const SizedBox(height: AppSpacing.md),
            Text(
              lang.translate('primary_contact_info'),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.translate('ok')),
          ),
        ],
      ),
    );
  }
}