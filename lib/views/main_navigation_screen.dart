import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:daily_expense_tracker/controllers/nav_controller.dart';
import 'package:daily_expense_tracker/views/home/premium_home_screen.dart'; // Central Navigation Timeline Hub
import 'package:daily_expense_tracker/views/history/history_screen.dart';
import 'package:daily_expense_tracker/views/analytics/analytics_hub_screen.dart'; // Merged Hub
import 'package:daily_expense_tracker/views/settings/settings_screen.dart';
import 'package:daily_expense_tracker/views/widgets/add_expense_sheet.dart';
import 'package:daily_expense_tracker/views/widgets/bouncing_button.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navController = Get.put(NavController());
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    // 4 Symmetrical screens (Dashboard replaced with Premium Home Timeline Hub)
    final List<Widget> screens = [
      const PremiumHomeScreen(),
      const HistoryScreen(),
      const AnalyticsHubScreen(), // Unified Hub (Stats + Categories)
      const SettingsScreen(),
    ];

    return Scaffold(
      body: Obx(() => PageTransitionSwitcher(
        currentIndex: navController.currentIndex.value,
        children: screens,
      )),
      floatingActionButton: _buildAnimatedFAB(theme),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          elevation: 0,
          padding: EdgeInsets.zero,
          color: theme.cardTheme.color ?? theme.scaffoldBackgroundColor,
          child: SafeArea(
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  // Left Side Tabs (Home Timeline & Transactions)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInteractiveTab(0, Icons.grid_view_rounded, 'Home', navController, theme),
                        _buildInteractiveTab(1, Icons.receipt_long_rounded, 'Txns', navController, theme),
                      ],
                    ),
                  ),

                  // Center Gap for Floating Action Button
                  SizedBox(width: size.width * 0.16),

                  // Right Side Tabs (Analytics & Settings)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInteractiveTab(2, Icons.analytics_outlined, 'Analytics', navController, theme),
                        _buildInteractiveTab(3, Icons.person_outline_rounded, 'Settings', navController, theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveTab(
      int index,
      IconData icon,
      String label,
      NavController controller,
      ThemeData theme,
      ) {
    return Obx(() {
      final isSelected = controller.currentIndex.value == index;
      final activeColor = theme.colorScheme.primary;
      final inactiveColor = theme.disabledColor;

      return Expanded(
        child: GestureDetector(
          onTap: () => controller.changeIndex(index),
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 14 : 0,
                  vertical: isSelected ? 6 : 0,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: isSelected ? 20 : 18,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  color: isSelected ? activeColor : inactiveColor,
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAnimatedFAB(ThemeData theme) {
    return BouncingButton(
      onTap: () {
        Get.bottomSheet(
          const AddExpenseSheet(),
          isScrollControlled: true,
          ignoreSafeArea: false,
          enterBottomSheetDuration: const Duration(milliseconds: 300),
          exitBottomSheetDuration: const Duration(milliseconds: 200),
        );
      },
      child: Container(
        height: 54,
        width: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.primary.withBlue(230)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

// Fade Slide Page Transition Swapper
class PageTransitionSwitcher extends StatelessWidget {
  final int currentIndex;
  final List<Widget> children;

  const PageTransitionSwitcher({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.02),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(currentIndex),
        child: children[currentIndex],
      ),
    );
  }
}