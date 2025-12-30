import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/responsive_utils.dart' as app_utils;
import '../../theme/admin_theme.dart';
import '../../providers/admin_auth_provider.dart';
import '../../widgets/layout/admin_sidebar.dart';
import '../../widgets/layout/admin_header.dart';
import '../../widgets/layout/admin_content.dart';
import '../../models/navigation_item.dart';

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
                          // Header
                          AdminHeader(
                            selectedItem: _selectedItem,
                            onMenuPressed: _toggleSidebar,
                            isSidebarCollapsed: _isDesktopSidebarCollapsed,
                          ),

                          // Content
                          Expanded(
                            child: AdminContent(selectedItem: _selectedItem),
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
