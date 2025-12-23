import 'package:flutter/material.dart';
import '../../../theme/admin_theme.dart';
import '../../../models/navigation_item.dart';

class CreatorApprovalModule extends StatelessWidget {
  const CreatorApprovalModule({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AdminTheme.cardDark,
              borderRadius: BorderRadius.circular(AdminTheme.radiusXl),
              border: Border.all(
                color: AdminTheme.borderColor.withOpacity(0.3),
              ),
            ),
            child: Icon(
              NavigationItem.creatorApproval.icon,
              size: 60,
              color: NavigationItem.creatorApproval.color,
            ),
          ),
          
          const SizedBox(height: AdminTheme.spacingXl),
          
          Text(
            NavigationItem.creatorApproval.title,
            style: AdminTheme.headlineLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AdminTheme.spacingSm),
          
          Text(
            NavigationItem.creatorApproval.description,
            style: AdminTheme.bodyLarge.copyWith(
              color: AdminTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AdminTheme.spacingXl),
          
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AdminTheme.spacingLg,
              vertical: AdminTheme.spacingMd,
            ),
            decoration: BoxDecoration(
              color: NavigationItem.creatorApproval.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
              border: Border.all(
                color: NavigationItem.creatorApproval.color.withOpacity(0.3),
              ),
            ),
            child: Text(
              'Coming Soon',
              style: AdminTheme.bodyMedium.copyWith(
                color: NavigationItem.creatorApproval.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


