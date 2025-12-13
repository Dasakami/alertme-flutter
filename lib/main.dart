import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/providers/auth_provider.dart';
import 'package:alertme/providers/contact_provider.dart';
import 'package:alertme/providers/sos_provider.dart';
import 'package:alertme/providers/geozone_provider.dart';
import 'package:alertme/providers/subscription_provider.dart';
import 'package:alertme/providers/language_provider.dart';
import 'package:alertme/screens/onboarding_screen.dart';
import 'package:alertme/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AlertMeApp());
}

class AlertMeApp extends StatelessWidget {
  const AlertMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Provider должен быть первым
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..init(),
        ),
        
        // Остальные провайдеры
        ChangeNotifierProvider(create: (_) => ContactProvider()),
        ChangeNotifierProvider(create: (_) => SOSProvider()),
        ChangeNotifierProvider(create: (_) => GeozoneProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Загружаем планы подписок если пользователь авторизован
          if (authProvider.isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<SubscriptionProvider>().loadPlans();
            });
          }
          
          return MaterialApp(
            title: 'AlertMe',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: ThemeMode.system,
            home: authProvider.isAuthenticated 
                ? const HomeScreen() 
                : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}