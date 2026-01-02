import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/admin_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;
  final double? fontSize;

  const UserAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    this.radius = 20,
    this.fontSize,
  });

  Widget _buildInitials() {
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: TextStyle(
        color: AdminTheme.primaryPurple,
        fontWeight: FontWeight.bold,
        fontSize: fontSize ?? radius * 0.8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage = photoUrl != null && photoUrl!.isNotEmpty;

    if (!hasImage) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AdminTheme.primaryPurple.withOpacity(0.2),
        child: _buildInitials(),
      );
    }

    return CachedNetworkImage(
      imageUrl: photoUrl!,
      imageBuilder: (context, imageProvider) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: AdminTheme.primaryPurple.withOpacity(0.2),
          backgroundImage: imageProvider,
        );
      },
      placeholder: (context, url) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: AdminTheme.primaryPurple.withOpacity(0.2),
          child: SizedBox(
            width: radius * 0.6,
            height: radius * 0.6,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AdminTheme.primaryPurple,
              ),
            ),
          ),
        );
      },
      errorWidget: (context, url, error) {
        // Silently fall back to initials without console spam
        return CircleAvatar(
          radius: radius,
          backgroundColor: AdminTheme.primaryPurple.withOpacity(0.2),
          child: _buildInitials(),
        );
      },
    );
  }
}
