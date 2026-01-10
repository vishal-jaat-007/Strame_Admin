import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../theme/admin_theme.dart';
import '../../../models/navigation_item.dart';
import '../../../widgets/dashboard/stats_cards.dart';
import '../../../widgets/dashboard/analytics_charts.dart';
import '../../../widgets/dashboard/recent_activities.dart';
import '../../../widgets/dashboard/quick_actions.dart';

class DashboardModule extends StatefulWidget {
  final ValueChanged<NavigationItem> onNavItemChanged;
  const DashboardModule({super.key, required this.onNavItemChanged});

  @override
  State<DashboardModule> createState() => _DashboardModuleState();
}

class _DashboardModuleState extends State<DashboardModule>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final screenWidth = MediaQuery.of(context).size.width;

    // Use stacked layout for screens smaller than 900px to avoid overflow in content sidebars
    final shouldStack = screenWidth < 900;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            _buildWelcomeHeader(),

            const SizedBox(height: AdminTheme.spacingXl),

            // Stats cards
            const StatsCards(),

            const SizedBox(height: AdminTheme.spacingXl),

            // Charts
            const AnalyticsCharts(),

            const SizedBox(height: AdminTheme.spacingXl),

            // Recent activities and quick actions
            if (shouldStack || isMobile) ...[
              // Mobile/Small tablet layout - stacked
              const RecentActivities(),
              const SizedBox(height: AdminTheme.spacingXl),
              QuickActions(onNavItemChanged: widget.onNavItemChanged),
            ] else ...[
              // Desktop/Tablet layout - side by side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recent activities
                  Expanded(flex: 2, child: const RecentActivities()),

                  const SizedBox(width: AdminTheme.spacingLg),

                  // Quick actions
                  Expanded(
                    flex: 1,
                    child: QuickActions(
                      onNavItemChanged: widget.onNavItemChanged,
                    ),
                  ),
                ],
              ),
            ],

            // Bottom padding
            const SizedBox(height: AdminTheme.spacingXl),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;

    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Container(
      padding: EdgeInsets.all(
        isMobile ? AdminTheme.spacingLg : AdminTheme.spacingXl,
      ),
      decoration: BoxDecoration(
        gradient: AdminTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AdminTheme.primaryPurple.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child:
          isMobile
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mobile layout - stacked
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$greeting, Admin!',
                          style: AdminTheme.headlineMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(
                            AdminTheme.radiusXl,
                          ),
                        ),
                        child: const Icon(
                          Icons.dashboard_rounded,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AdminTheme.spacingSm),

                  Text(
                    'Welcome to your Strame Admin Dashboard. Monitor your platform\'s performance and manage operations efficiently.',
                    style: AdminTheme.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),

                  const SizedBox(height: AdminTheme.spacingMd),

                  // Current date and time
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AdminTheme.spacingMd,
                      vertical: AdminTheme.spacingSm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                    ),
                    child: Text(
                      '${_formatDate(now)} • ${_formatTime(now)}',
                      style: AdminTheme.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              )
              : Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting, Admin!',
                          style: AdminTheme.headlineLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: AdminTheme.spacingSm),

                        Text(
                          'Welcome to your Strame Admin Dashboard. Monitor your platform\'s performance and manage operations efficiently.',
                          style: AdminTheme.bodyLarge.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),

                        const SizedBox(height: AdminTheme.spacingMd),

                        // Current date and time
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AdminTheme.spacingMd,
                            vertical: AdminTheme.spacingSm,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(
                              AdminTheme.radiusSm,
                            ),
                          ),
                          child: Text(
                            '${_formatDate(now)} • ${_formatTime(now)}',
                            style: AdminTheme.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dashboard icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AdminTheme.radiusXl),
                    ),
                    child: const Icon(
                      Icons.dashboard_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour =
        time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}


