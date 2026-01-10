import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/admin_theme.dart';
import '../../models/navigation_item.dart';
import '../../providers/admin_auth_provider.dart';
import '../../utils/responsive_utils.dart' as app_utils;
import '../common/glass_card.dart';
import '../dialogs/global_search_dialog.dart';

class AdminHeader extends StatelessWidget {
  final NavigationItem selectedItem;
  final VoidCallback onMenuPressed;
  final ValueChanged<NavigationItem> onNavItemChanged;
  final bool isSidebarCollapsed;

  const AdminHeader({
    super.key,
    required this.selectedItem,
    required this.onMenuPressed,
    required this.onNavItemChanged,
    required this.isSidebarCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = app_utils.AppResponsiveUtils.isMobile(context);

    return Container(
      height: app_utils.AppResponsiveUtils.responsive(
        context,
        mobile: 56.0,
        tablet: 64.0,
        desktop: AdminTheme.headerHeight,
      ),
      padding: app_utils.AppResponsiveUtils.responsivePadding(
        context,
      ).copyWith(top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: AdminTheme.backgroundSecondary.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: AdminTheme.borderColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Menu button (mobile only)
          if (isMobile)
            IconButton(
              onPressed: onMenuPressed,
              icon: const Icon(Icons.menu, color: AdminTheme.textPrimary),
              tooltip: 'Toggle Menu',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),

          // Page title and breadcrumb
          Expanded(child: _buildPageTitle(context)),

          SizedBox(
            width: app_utils.AppResponsiveUtils.responsiveSpacing(context),
          ),

          // Header actions
          _buildHeaderActions(context),
        ],
      ),
    );
  }

  Widget _buildPageTitle(BuildContext context) {
    final isMobile = app_utils.AppResponsiveUtils.isMobile(context);
    final iconSize = app_utils.AppResponsiveUtils.responsive(
      context,
      mobile: 20.0,
      tablet: 24.0,
      desktop: 32.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Page title
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: selectedItem.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
              ),
              child: Icon(
                selectedItem.icon,
                color: selectedItem.color,
                size: iconSize * 0.6,
              ),
            ),

            SizedBox(
              width:
                  app_utils.AppResponsiveUtils.responsiveSpacing(context) * 0.5,
            ),

            Flexible(
              child: Text(
                selectedItem.title,
                style: TextStyle(
                  fontSize: app_utils.AppResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 16,
                    tablet: 18,
                    desktop: 20,
                  ),
                  fontWeight: FontWeight.bold,
                  color: AdminTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        if (!isMobile) ...[
          const SizedBox(height: 2),

          // Breadcrumb (hide on mobile)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'Admin Panel',
                  style: TextStyle(
                    fontSize: app_utils.AppResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 12,
                    ),
                    color: AdminTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              SizedBox(
                width:
                    app_utils.AppResponsiveUtils.responsiveSpacing(context) *
                    0.25,
              ),

              Icon(
                Icons.chevron_right,
                size: 14,
                color: AdminTheme.textSecondary,
              ),

              SizedBox(
                width:
                    app_utils.AppResponsiveUtils.responsiveSpacing(context) *
                    0.25,
              ),

              Flexible(
                child: Text(
                  selectedItem.title,
                  style: TextStyle(
                    fontSize: app_utils.AppResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 12,
                    ),
                    color: selectedItem.color,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildHeaderActions(BuildContext context) {
    return Consumer<AdminAuthProvider>(
      builder: (context, authProvider, child) {
        final isMobile = app_utils.AppResponsiveUtils.isMobile(context);
        final screenWidth = MediaQuery.of(context).size.width;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show fewer actions on mobile and medium screens
            if (!isMobile && screenWidth > 900) ...[
              // Search button (hide on medium screens)
              _buildActionButton(
                context,
                icon: Icons.search_rounded,
                tooltip: 'Search',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => GlobalSearchDialog(
                          onNavItemChanged: onNavItemChanged,
                        ),
                  );
                },
              ),

              SizedBox(
                width:
                    app_utils.AppResponsiveUtils.responsiveSpacing(context) *
                    0.5,
              ),
            ],

            // Notifications (always show)
            _buildActionButton(
              context,
              icon: Icons.notifications_rounded,
              tooltip: 'Notifications',
              hasNotification: NavigationItem.notifications.hasNotification,
              onPressed: () => onNavItemChanged(NavigationItem.notifications),
            ),

            if (!isMobile && screenWidth > 1000) ...[
              SizedBox(
                width:
                    app_utils.AppResponsiveUtils.responsiveSpacing(context) *
                    0.5,
              ),

              // Settings (hide on medium screens)
              _buildActionButton(
                context,
                icon: Icons.settings_rounded,
                tooltip: 'Settings',
                onPressed: () => onNavItemChanged(NavigationItem.settings),
              ),
            ],

            SizedBox(
              width:
                  app_utils.AppResponsiveUtils.responsiveSpacing(context) * 0.5,
            ),

            // Admin profile
            _buildAdminProfile(authProvider, context),
          ],
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool hasNotification = false,
  }) {
    final isMobile = app_utils.AppResponsiveUtils.isMobile(context);
    final buttonSize = app_utils.AppResponsiveUtils.responsive(
      context,
      mobile: 32.0,
      tablet: 36.0,
      desktop: 40.0,
    );

    return GlassCard(
      padding: EdgeInsets.all(
        app_utils.AppResponsiveUtils.responsiveSpacing(context) * 0.25,
      ),
      child: SizedBox(
        width: buttonSize,
        height: buttonSize,
        child: Stack(
          children: [
            IconButton(
              onPressed: onPressed,
              icon: Icon(
                icon,
                color: AdminTheme.textSecondary,
                size: app_utils.AppResponsiveUtils.responsive(
                  context,
                  mobile: 16.0,
                  tablet: 18.0,
                  desktop: 20.0,
                ),
              ),
              tooltip: tooltip,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: buttonSize,
                minHeight: buttonSize,
              ),
            ),

            if (hasNotification)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AdminTheme.errorRed,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminProfile(
    AdminAuthProvider authProvider,
    BuildContext context,
  ) {
    final isMobile = app_utils.AppResponsiveUtils.isMobile(context);
    final admin = authProvider.currentAdmin;

    return GlassCard(
      padding: EdgeInsets.symmetric(
        horizontal:
            app_utils.AppResponsiveUtils.responsiveSpacing(context) * 0.5,
        vertical:
            app_utils.AppResponsiveUtils.responsiveSpacing(context) * 0.25,
      ),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
        ),
        color: AdminTheme.cardDark,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            CircleAvatar(
              radius: app_utils.AppResponsiveUtils.responsive(
                context,
                mobile: 12.0,
                tablet: 14.0,
                desktop: 16.0,
              ),
              backgroundColor: AdminTheme.primaryPurple,
              backgroundImage:
                  admin?.photoUrl != null
                      ? NetworkImage(admin!.photoUrl!)
                      : null,
              child:
                  admin?.photoUrl == null
                      ? Icon(
                        Icons.person,
                        color: Colors.white,
                        size: app_utils.AppResponsiveUtils.responsive(
                          context,
                          mobile: 12.0,
                          tablet: 14.0,
                          desktop: 16.0,
                        ),
                      )
                      : null,
            ),

            if (!isMobile) ...[
              const SizedBox(width: 8),

              // Name (hide on mobile)
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 120,
                  maxHeight: 36, // Ensure it fits within header
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      admin?.name ?? 'Admin',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AdminTheme.textPrimary,
                        height: 1.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      'Administrator',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AdminTheme.textSecondary,
                        height: 1.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),

              // Dropdown arrow
              const Icon(
                Icons.keyboard_arrow_down,
                color: AdminTheme.textSecondary,
                size: 16,
              ),
            ],
          ],
        ),
        itemBuilder:
            (context) => [
              PopupMenuItem<String>(
                value: 'logout',
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: AdminTheme.errorRed.withOpacity(0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Sign Out',
                      style: AdminTheme.bodyMedium.copyWith(
                        color: AdminTheme.errorRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
        onSelected: (value) {
          debugPrint('🔘 [AdminHeader] Menu item selected: $value');
          if (value == 'logout') {
            _showLogoutConfirmation(context, authProvider);
          }
        },
      ),
    );
  }

  void _showLogoutConfirmation(
    BuildContext context,
    AdminAuthProvider authProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AdminTheme.cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            ),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: AdminTheme.textPrimary),
            ),
            content: const Text(
              'Are you sure you want to sign out from the Admin Panel?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AdminTheme.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  authProvider.signOut();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.errorRed,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );
  }
}
