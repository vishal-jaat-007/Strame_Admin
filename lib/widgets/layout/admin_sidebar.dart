import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/admin_theme.dart';
import '../../models/navigation_item.dart';
import '../../providers/admin_auth_provider.dart';
import '../common/glass_card.dart';

class AdminSidebar extends StatefulWidget {
  final bool isCollapsed;
  final NavigationItem selectedItem;
  final Function(NavigationItem) onItemSelected;
  final VoidCallback onToggle;

  const AdminSidebar({
    super.key,
    required this.isCollapsed,
    required this.selectedItem,
    required this.onItemSelected,
    required this.onToggle,
  });

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AdminTheme.sidebarDark, AdminTheme.cardDarker],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border(
            right: BorderSide(
              color: AdminTheme.borderColor.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Navigation items
            Expanded(child: _buildNavigationItems()),

            // Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(
        widget.isCollapsed ? AdminTheme.spacingMd : AdminTheme.spacingLg,
      ),
      child: Column(
        children: [
          // Logo and toggle button
          if (widget.isCollapsed)
            // Collapsed layout - vertical stack
            Column(
              children: [
                // Logo
                GestureDetector(
                  onTap: widget.onToggle,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AdminTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                      boxShadow: AdminTheme.glassShadow,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            )
          else
            // Expanded layout - horizontal row
            Row(
              children: [
                // Logo
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AdminTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                    boxShadow: AdminTheme.glassShadow,
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),

                const SizedBox(width: AdminTheme.spacingMd),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Strame',
                        style: AdminTheme.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Admin Panel',
                        style: AdminTheme.bodySmall.copyWith(
                          color: AdminTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Toggle button
                IconButton(
                  onPressed: widget.onToggle,
                  icon: const Icon(Icons.menu, color: AdminTheme.textSecondary),
                  tooltip: 'Collapse Sidebar',
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),

          const SizedBox(height: AdminTheme.spacingLg),

          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AdminTheme.borderColor.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItems() {
    final items = [
      NavigationItem.dashboard,
      NavigationItem.users,
      NavigationItem.creators,
      NavigationItem.creatorApproval,
      NavigationItem.calls,
      NavigationItem.live,
      NavigationItem.withdrawals,
      NavigationItem.transactions,
      NavigationItem.notifications,
      NavigationItem.content,
    ];

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal:
            widget.isCollapsed ? AdminTheme.spacingSm : AdminTheme.spacingMd,
        vertical: AdminTheme.spacingMd,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = item == widget.selectedItem;

        return Padding(
          padding: const EdgeInsets.only(bottom: AdminTheme.spacingSm),
          child: _buildNavigationItem(item, isSelected),
        );
      },
    );
  }

  Widget _buildNavigationItem(NavigationItem item, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: isSelected ? AdminTheme.primaryGradient : null,
        color: isSelected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
        border:
            isSelected ? null : Border.all(color: Colors.transparent, width: 1),
        boxShadow:
            isSelected
                ? [
                  BoxShadow(
                    color: item.color.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onItemSelected(item),
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal:
                  widget.isCollapsed
                      ? AdminTheme.spacingSm
                      : AdminTheme.spacingMd,
              vertical: AdminTheme.spacingMd,
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? Colors.white.withOpacity(0.2)
                            : item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                  ),
                  child: Icon(
                    item.icon,
                    color: isSelected ? Colors.white : item.color,
                    size: 20,
                  ),
                ),

                if (!widget.isCollapsed) ...[
                  const SizedBox(width: AdminTheme.spacingMd),

                  // Title and description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: AdminTheme.bodyMedium.copyWith(
                            color:
                                isSelected
                                    ? Colors.white
                                    : AdminTheme.textPrimary,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        if (!widget.isCollapsed) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.description,
                            style: AdminTheme.bodySmall.copyWith(
                              color:
                                  isSelected
                                      ? Colors.white.withOpacity(0.8)
                                      : AdminTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Notification badge
                  if (item.hasNotification)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AdminTheme.errorRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(
        widget.isCollapsed ? AdminTheme.spacingMd : AdminTheme.spacingLg,
      ),
      child: Column(
        children: [
          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AdminTheme.borderColor.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(height: AdminTheme.spacingLg),

          // Admin profile
          Consumer<AdminAuthProvider>(
            builder: (context, authProvider, child) {
              final admin = authProvider.currentAdmin;

              return GlassCard(
                padding: EdgeInsets.all(
                  widget.isCollapsed
                      ? AdminTheme.spacingSm *
                          0.5 // Reduced padding
                      : AdminTheme.spacingMd,
                ),
                child:
                    widget.isCollapsed
                        ? Center(
                          child: CircleAvatar(
                            radius: 12, // Smaller in collapsed state
                            backgroundColor: AdminTheme.primaryPurple,
                            backgroundImage:
                                admin?.photoUrl != null
                                    ? NetworkImage(admin!.photoUrl!)
                                    : null,
                            child:
                                admin?.photoUrl == null
                                    ? const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 12,
                                    )
                                    : null,
                          ),
                        )
                        : Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AdminTheme.primaryPurple,
                              backgroundImage:
                                  admin?.photoUrl != null
                                      ? NetworkImage(admin!.photoUrl!)
                                      : null,
                              child:
                                  admin?.photoUrl == null
                                      ? const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 20,
                                      )
                                      : null,
                            ),

                            const SizedBox(width: AdminTheme.spacingMd),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    admin?.name ?? 'Admin',
                                    style: AdminTheme.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    admin?.email ?? '',
                                    style: AdminTheme.bodySmall.copyWith(
                                      color: AdminTheme.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // Logout button
                            IconButton(
                              onPressed: () => authProvider.signOut(),
                              icon: const Icon(
                                Icons.logout_rounded,
                                color: AdminTheme.textSecondary,
                                size: 18,
                              ),
                              tooltip: 'Sign Out',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
              );
            },
          ),

          if (!widget.isCollapsed) ...[
            const SizedBox(height: AdminTheme.spacingMd),

            // Version info
            Text(
              'v1.0.0',
              style: AdminTheme.labelSmall.copyWith(
                color: AdminTheme.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}























