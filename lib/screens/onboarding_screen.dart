import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:alertme/theme.dart';
import 'package:alertme/providers/language_provider.dart';
import 'package:alertme/screens/login_screen.dart';
import 'package:alertme/screens/permissions_request_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    
    final List<OnboardingPage> pages = [
      OnboardingPage(
        icon: Icons.shield_outlined,
        title: lang.translate('onboarding_title_1'),
        description: lang.translate('onboarding_desc_1'),
        color: AppColors.deepBlue,
      ),
      OnboardingPage(
        icon: Icons.people_outline,
        title: lang.translate('onboarding_title_2'),
        description: lang.translate('onboarding_desc_2'),
        color: AppColors.softCyan,
      ),
      OnboardingPage(
        icon: Icons.verified_user_outlined,
        title: lang.translate('onboarding_title_3'),
        description: lang.translate('onboarding_desc_3'),
        color: AppColors.deepBlue,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: AppSpacing.paddingLg,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _LanguageToggle(lang: lang),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: pages.length,
                itemBuilder: (context, index) => _OnboardingPageWidget(page: pages[index]),
              ),
            ),
            Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: pages.length,
                    effect: ExpandingDotsEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: AppColors.deepBlue,
                      dotColor: Theme.of(context).brightness == Brightness.light 
                        ? AppColors.borderLight 
                        : AppColors.borderDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == pages.length - 1) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const PermissionsRequestScreen()),
                          );
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Text(_currentPage == pages.length - 1 ? lang.translate('get_started') : 'Далее'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  final LanguageProvider lang;

  const _LanguageToggle({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.deepBlue, width: 1.5),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageButton(context, 'RU', 'ru'),
          Container(width: 1.5, height: 20, color: AppColors.deepBlue),
          _buildLanguageButton(context, 'KG', 'kg'),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(BuildContext context, String label, String code) {
    final isSelected = lang.currentLanguage == code;
    return InkWell(
      onTap: () => lang.setLanguage(code),
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.deepBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          label,
          style: context.textStyles.labelLarge?.copyWith(
            color: isSelected ? Colors.white : AppColors.deepBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;

  const _OnboardingPageWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.horizontalXl,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 64, color: page.color),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            page.title,
            style: context.textStyles.displaySmall?.semiBold,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            page.description,
            style: context.textStyles.bodyLarge?.withColor(AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
