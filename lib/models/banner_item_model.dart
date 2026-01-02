import 'package:flutter/material.dart';

class BannerThemeData {
  final String id;
  final String name;
  final List<Color> gradientColors;
  final Color textColor;
  final Color accentColor;
  final String? pattern; // 'dots', 'waves', 'geometric', etc.

  const BannerThemeData({
    required this.id,
    required this.name,
    required this.gradientColors,
    required this.textColor,
    required this.accentColor,
    this.pattern,
  });
}

class BannerItem {
  final String id;
  final String title;
  final String subtitle;
  final String themeId;
  final String actionTarget; // Deep link or action
  final String? icon; // Emoji or Icon name
  final bool isActive;
  final int priority;
  final DateTime? createdAt;
  final String? imageUrl; // Optional, if they want a photo instead of theme

  BannerItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.themeId,
    required this.actionTarget,
    this.icon,
    this.isActive = true,
    this.priority = 0,
    this.createdAt,
    this.imageUrl,
  });

  factory BannerItem.fromFirestore(Map<String, dynamic> data, String id) {
    return BannerItem(
      id: id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      themeId: data['themeId'] ?? 'default',
      actionTarget: data['actionTarget'] ?? '',
      icon: data['icon'],
      isActive: data['isActive'] ?? true,
      priority: data['priority'] ?? 0,
      createdAt: (data['createdAt'] as dynamic)?.toDate(),
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'subtitle': subtitle,
      'themeId': themeId,
      'actionTarget': actionTarget,
      'icon': icon,
      'isActive': isActive,
      'priority': priority,
      'imageUrl': imageUrl,
      'createdAt': createdAt ?? DateTime.now(),
    };
  }
}

// Pre-defined Themes (50+ can be generated or listed here)
final List<BannerThemeData> bannerThemes = [
  const BannerThemeData(
    id: 'premium_gold',
    name: 'Premium Gold',
    gradientColors: [Color(0xFFB8860B), Color(0xFFFFD700)],
    textColor: Colors.black87,
    accentColor: Colors.white,
  ),
  const BannerThemeData(
    id: 'cyberpunk_pink',
    name: 'Cyberpunk Pink',
    gradientColors: [Color(0xFFFF00CC), Color(0xFF333399)],
    textColor: Colors.white,
    accentColor: Color(0xFF00FFFF),
  ),
  const BannerThemeData(
    id: 'royal_purple',
    name: 'Royal Purple',
    gradientColors: [Color(0xFF4B0082), Color(0xFF8B008B)],
    textColor: Colors.white,
    accentColor: Color(0xFFFFD700),
  ),
  const BannerThemeData(
    id: 'ocean_blue',
    name: 'Ocean Blue',
    gradientColors: [Color(0xFF00008B), Color(0xFF00CED1)],
    textColor: Colors.white,
    accentColor: Colors.white70,
  ),
  const BannerThemeData(
    id: 'emerald_green',
    name: 'Emerald Green',
    gradientColors: [Color(0xFF006400), Color(0xFF32CD32)],
    textColor: Colors.white,
    accentColor: Colors.white,
  ),
  const BannerThemeData(
    id: 'sunset_orange',
    name: 'Sunset Orange',
    gradientColors: [Color(0xFFFF4500), Color(0xFFFFA500)],
    textColor: Colors.white,
    accentColor: Colors.black54,
  ),
  const BannerThemeData(
    id: 'midnight_sky',
    name: 'Midnight Sky',
    gradientColors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
    textColor: Colors.white,
    accentColor: Color(0xFFe94560),
  ),
  const BannerThemeData(
    id: 'electric_violet',
    name: 'Electric Violet',
    gradientColors: [Color(0xFF8e2de2), Color(0xFF4a00e0)],
    textColor: Colors.white,
    accentColor: Colors.white,
  ),
  const BannerThemeData(
    id: 'toxic_green',
    name: 'Toxic Green',
    gradientColors: [Color(0xFF0F2027), Color(0xFF2C5364)],
    textColor: Color(0xFFCCFF00),
    accentColor: Color(0xFFCCFF00),
  ),
  const BannerThemeData(
    id: 'cherry_blossom',
    name: 'Cherry Blossom',
    gradientColors: [Color(0xFFffafbd), Color(0xFFffc3a0)],
    textColor: Color(0xFF5D101D),
    accentColor: Colors.white,
  ),
  // ... adding more for variety
  ...List.generate(
    40,
    (index) => BannerThemeData(
      id: 'gen_theme_$index',
      name: 'Theme Variant $index',
      gradientColors: [
        HSLColor.fromAHSL(1, (index * 45) % 360, 0.6, 0.4).toColor(),
        HSLColor.fromAHSL(1, (index * 45 + 30) % 360, 0.7, 0.6).toColor(),
      ],
      textColor: Colors.white,
      accentColor: Colors.white.withOpacity(0.5),
    ),
  ),
];
