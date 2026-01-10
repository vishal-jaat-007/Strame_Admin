import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../utils/responsive_utils.dart' as app_utils;
import '../../theme/admin_theme.dart';
import '../../providers/admin_auth_provider.dart';
import '../../widgets/layout/admin_sidebar.dart';
import '../../widgets/layout/admin_header.dart';
import '../../widgets/layout/admin_content.dart';
import '../../models/navigation_item.dart';
import '../../services/app_config_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _sidebarController;
  late Animation<double> _sidebarAnimation;

  // Separate states for mobile and desktop
  bool _isDesktopSidebarCollapsed = false;
  bool _isMobileSidebarOpen = false;

  NavigationItem _selectedItem = NavigationItem.dashboard;
  final AppConfigService _configService = AppConfigService();

  @override
  void initState() {
    super.initState();

    _sidebarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _sidebarAnimation = Tween<double>(
      begin: AdminTheme.sidebarWidth,
      end: AdminTheme.sidebarCollapsedWidth,
    ).animate(
      CurvedAnimation(parent: _sidebarController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _sidebarController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    final isMobile = app_utils.AppResponsiveUtils.isMobile(context);

    setState(() {
      if (isMobile) {
        _isMobileSidebarOpen = !_isMobileSidebarOpen;
      } else {
        _isDesktopSidebarCollapsed = !_isDesktopSidebarCollapsed;
        if (_isDesktopSidebarCollapsed) {
          _sidebarController.forward();
        } else {
          _sidebarController.reverse();
        }
      }
    });
  }

  void _onNavigationItemSelected(NavigationItem item) {
    setState(() {
      _selectedItem = item;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = app_utils.AppResponsiveUtils.isMobile(context);

    return Consumer<AdminAuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return const SizedBox.shrink();
        }

        return Scaffold(
          body: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: AdminTheme.backgroundGradient,
                ),
                child: Row(
                  children: [
                    // Sidebar (desktop/tablet - permanent)
                    if (!isMobile)
                      AnimatedBuilder(
                        animation: _sidebarAnimation,
                        builder: (context, child) {
                          return SizedBox(
                            width: _sidebarAnimation.value,
                            child: AdminSidebar(
                              isCollapsed: _isDesktopSidebarCollapsed,
                              selectedItem: _selectedItem,
                              onItemSelected: _onNavigationItemSelected,
                              onToggle: _toggleSidebar,
                            ),
                          );
                        },
                      ),

                    // Main content area
                    Expanded(
                      child: Column(
                        children: [
                          // Maintenance Banner
                          StreamBuilder<Map<String, dynamic>>(
                            stream: _configService.getSystemSettings(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                debugPrint(
                                  'Warning: Dashboard maintenance stream error: ${snapshot.error}',
                                );
                                return const SizedBox.shrink();
                              }
                              final settings = snapshot.data;
                              final isMaintenance =
                                  settings?['maintenanceMode'] ?? false;

                              if (!isMaintenance)
                                return const SizedBox.shrink();

                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: AdminTheme.warningOrange.withOpacity(
                                    0.9,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.construction_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'MAINTENANCE MODE ACTIVE: Platform access is restricted for regular users.',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.white.withOpacity(0.8),
                                      size: 18,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // Header
                          AdminHeader(
                            selectedItem: _selectedItem,
                            onMenuPressed: _toggleSidebar,
                            onNavItemChanged: _onNavigationItemSelected,
                            isSidebarCollapsed: _isDesktopSidebarCollapsed,
                          ),

                          // Content
                          Expanded(
                            child: AdminContent(
                              selectedItem: _selectedItem,
                              onNavItemChanged: _onNavigationItemSelected,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Mobile sidebar - overlay drawer
              if (isMobile && _isMobileSidebarOpen)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _toggleSidebar,
                    child: Container(
                      color: Colors.black54,
                      child: GestureDetector(
                        onTap: () {}, // Prevent close when tapping sidebar
                        child: SizedBox(
                          width: AdminTheme.sidebarWidth,
                          child: AdminSidebar(
                            isCollapsed: false,
                            selectedItem: _selectedItem,
                            onItemSelected: (item) {
                              _onNavigationItemSelected(item);
                              _toggleSidebar(); // Auto-close on selection
                            },
                            onToggle: _toggleSidebar,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}


