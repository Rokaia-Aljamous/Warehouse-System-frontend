import 'package:flutter/material.dart';
import 'package:stock_app/views/screens/driver/driver_home_screen.dart';
import 'package:stock_app/views/widgets/auth_widgets.dart';
import 'package:stock_app/views/screens/warehouse/MyTasksScreen.dart';
import '../../../utils/constants.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.welcomeGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: h * 0.07),

                Text('Welcome', style: theme.textTheme.displayLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'in our system',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),

                SizedBox(height: h * 0.36),

                Text('Who are you?', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.lg),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ============================================================
                    // Delivery Driver → يروح على MyTasksScreen
                    // ============================================================
                    Expanded(
                      child: _RoleCard(
                        icon: Icons.local_shipping_outlined,
                        label: 'Delivery\nDriver',
                        borderRadius: AppDimensions.roleCardRadius,
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyTasksScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // ============================================================
                    // Worker Warehouse → يروح على MainShell
                    // ============================================================
                    Expanded(
                      child: _RoleCard(
                        icon: Icons.person_outline_rounded,
                        label: 'Worker\nWarehouse',
                        borderRadius: AppDimensions.roleCardRadiusFlipped,
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MainShell(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.borderRadius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppDimensions.roleCardHeight,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: AppDimensions.iconBoxSize,
              height: AppDimensions.iconBoxSize,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(
                  AppDimensions.iconBoxRadius,
                ),
              ),
              child: Icon(
                icon,
                size: AppDimensions.iconSize,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
