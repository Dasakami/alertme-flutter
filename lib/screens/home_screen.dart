import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/providers/auth_provider.dart';
import 'package:alertme/providers/contact_provider.dart';
import 'package:alertme/providers/sos_provider.dart';
import 'package:alertme/providers/language_provider.dart';
import 'package:alertme/screens/contacts_screen.dart';
import 'package:alertme/screens/safety_timer_screen.dart';
import 'package:alertme/screens/settings_screen.dart';
import 'package:alertme/screens/sos_active_screen.dart';
import 'package:alertme/widgets/sos_button.dart';
import 'package:alertme/widgets/mini_map.dart';
import 'package:alertme/widgets/quick_action_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final contactProvider = context.read<ContactProvider>();
    final sosProvider = context.read<SOSProvider>();

    if (authProvider.currentUser != null) {
      await contactProvider.loadContacts(authProvider.currentUser!.id);
      await sosProvider.loadEvents(authProvider.currentUser!.id);
    }
  }

  void _triggerSOS() async {
    final authProvider = context.read<AuthProvider>();
    final contactProvider = context.read<ContactProvider>();
    final sosProvider = context.read<SOSProvider>();

    if (authProvider.currentUser == null) return;
    
    if (contactProvider.contacts.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Добавьте хотя бы один контакт'),
          backgroundColor: AppColors.sosRed,
        ),
      );
      return;
    }

    final event = await sosProvider.triggerSOS(
      authProvider.currentUser!.id,
      contactProvider.contacts,
    );

    if (event != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SOSActiveScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: AppSpacing.horizontalLg + AppSpacing.verticalMd,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.translate('app_name'),
                        style: context.textStyles.titleLarge?.semiBold,
                      ),
                      Text(
                        authProvider.currentUser?.name ?? '',
                        style: context.textStyles.bodyMedium?.withColor(AppColors.textSecondary),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.horizontalLg,
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    const MiniMap(),
                    const SizedBox(height: AppSpacing.xxl),
                    SOSButton(onActivate: _triggerSOS),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      lang.translate('hold_for_sos'),
                      style: context.textStyles.bodyMedium?.withColor(AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Row(
                      children: [
                        Expanded(
                          child: QuickActionButton(
                            icon: Icons.people_outline,
                            label: lang.translate('contacts'),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ContactsScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: QuickActionButton(
                            icon: Icons.timer_outlined,
                            label: lang.translate('timer'),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SafetyTimerScreen()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}