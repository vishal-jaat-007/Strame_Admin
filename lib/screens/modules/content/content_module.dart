import 'package:flutter/material.dart';
import '../../../theme/admin_theme.dart';
import '../../../services/content_service.dart';
import '../../../models/banner_item_model.dart';
import '../../../widgets/common/glass_card.dart';

class ContentModule extends StatefulWidget {
  const ContentModule({super.key});

  @override
  State<ContentModule> createState() => _ContentModuleState();
}

class _ContentModuleState extends State<ContentModule> {
  final ContentService _contentService = ContentService();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context),

          const SizedBox(height: AdminTheme.spacingXl),

          // Main Section Split
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active Banners List
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Mobile Banners',
                      style: AdminTheme.headlineSmall,
                    ),
                    const SizedBox(height: AdminTheme.spacingMd),
                    StreamBuilder<List<BannerItem>>(
                      stream: _contentService.getBanners(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final banners = snapshot.data ?? [];
                        if (banners.isEmpty) {
                          return _buildEmptyState();
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: banners.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return _BannerListItem(
                              banner: banners[index],
                              onToggle:
                                  () => _contentService.toggleBanner(
                                    banners[index].id,
                                    banners[index].isActive,
                                  ),
                              onDelete:
                                  () => _contentService.deleteBanner(
                                    banners[index].id,
                                  ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AdminTheme.spacingXl),

              // Preview & Guide Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Live Preview Guide', style: AdminTheme.headlineSmall),
                    const SizedBox(height: AdminTheme.spacingMd),
                    const _MobileMockupPreview(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Content & Banners', style: AdminTheme.headlineMedium),
            const SizedBox(height: AdminTheme.spacingXs),
            Text(
              'Design and manage 50+ animated themes for your mobile app.',
              style: AdminTheme.bodyMedium.copyWith(
                color: AdminTheme.textSecondary,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showManagementDialog(context),
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text('Create Premium Banner'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminTheme.primaryPurple,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return GlassCard(
      padding: const EdgeInsets.all(AdminTheme.spacing3Xl),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.layers_clear_rounded,
              size: 64,
              color: AdminTheme.textSecondary.withOpacity(0.2),
            ),
            const SizedBox(height: AdminTheme.spacingMd),
            Text(
              'No banners tailored yet.',
              style: AdminTheme.headlineSmall.copyWith(
                color: AdminTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use the Premium Creator to add beautiful animated banners.',
              style: TextStyle(color: AdminTheme.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  void _showManagementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _BannerManagementDialog(),
    );
  }
}

class _BannerListItem extends StatelessWidget {
  final BannerItem banner;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _BannerListItem({
    required this.banner,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Find the theme
    final theme = bannerThemes.firstWhere(
      (t) => t.id == banner.themeId,
      orElse: () => bannerThemes.first,
    );

    return GlassCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Visual Preview Side
            Container(
              width: 240,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: theme.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AdminTheme.radiusLg),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (banner.icon != null)
                    Text(banner.icon!, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 8),
                  Text(
                    banner.title,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    banner.subtitle,
                    style: TextStyle(
                      color: theme.textColor.withOpacity(0.8),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Info Side
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Target: ${banner.actionTarget}',
                          style: AdminTheme.labelSmall.copyWith(
                            color: AdminTheme.textSecondary,
                          ),
                        ),
                        Row(
                          children: [
                            Switch(
                              value: banner.isActive,
                              onChanged: (_) => onToggle(),
                              activeColor: AdminTheme.successGreen,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_sweep_rounded,
                                color: AdminTheme.errorRed,
                              ),
                              onPressed: onDelete,
                              tooltip: 'Delete Banner',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'Theme: ${theme.name}',
                      style: AdminTheme.bodySmall.copyWith(
                        color: AdminTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerManagementDialog extends StatefulWidget {
  const _BannerManagementDialog();

  @override
  State<_BannerManagementDialog> createState() =>
      _BannerManagementDialogState();
}

class _BannerManagementDialogState extends State<_BannerManagementDialog> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _targetController = TextEditingController();
  String _selectedThemeId = bannerThemes.first.id;
  String? _selectedIcon = '🚀';

  final List<String> _icons = [
    '🚀',
    '🔥',
    '💎',
    '🎉',
    '🎁',
    '💰',
    '👑',
    '⭐',
    '❤️',
    '📺',
  ];

  @override
  Widget build(BuildContext context) {
    final selectedTheme = bannerThemes.firstWhere(
      (t) => t.id == _selectedThemeId,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 900,
        height: 700,
        decoration: BoxDecoration(
          color: AdminTheme.cardDark,
          borderRadius: BorderRadius.circular(AdminTheme.radiusXl),
          border: Border.all(color: AdminTheme.borderColor),
        ),
        child: Row(
          children: [
            // Settings Side
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(AdminTheme.spacingXl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Banner Designer',
                              style: AdminTheme.headlineSmall,
                            ),
                            const SizedBox(height: AdminTheme.spacingLg),

                            // Input Fields
                            _buildInputField(
                              'Main Title',
                              'e.g. Get 50% Bonus',
                              _titleController,
                            ),
                            const SizedBox(height: 16),
                            _buildInputField(
                              'Subtitle',
                              'e.g. Limited time offer on first recharge',
                              _subtitleController,
                            ),
                            const SizedBox(height: 16),
                            _buildInputField(
                              'Target / Deep Link',
                              'e.g. /wallet/add_coins',
                              _targetController,
                            ),

                            const SizedBox(height: 24),
                            Text(
                              'Select Theme (50+ Styles)',
                              style: AdminTheme.labelMedium,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: bannerThemes.length,
                                itemBuilder: (context, index) {
                                  final theme = bannerThemes[index];
                                  final isSelected =
                                      theme.id == _selectedThemeId;
                                  return GestureDetector(
                                    onTap:
                                        () => setState(
                                          () => _selectedThemeId = theme.id,
                                        ),
                                    child: Container(
                                      width: 80,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: theme.gradientColors,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AdminTheme.radiusMd,
                                        ),
                                        border:
                                            isSelected
                                                ? Border.all(
                                                  color: Colors.white,
                                                  width: 3,
                                                )
                                                : null,
                                        boxShadow:
                                            isSelected
                                                ? [
                                                  BoxShadow(
                                                    color: theme
                                                        .gradientColors
                                                        .first
                                                        .withOpacity(0.5),
                                                    blurRadius: 10,
                                                  ),
                                                ]
                                                : null,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 24),
                            Text(
                              'Select Decorator Icon',
                              style: AdminTheme.labelMedium,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  _icons.map((icon) {
                                    final isSelected = _selectedIcon == icon;
                                    return GestureDetector(
                                      onTap:
                                          () => setState(
                                            () => _selectedIcon = icon,
                                          ),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color:
                                              isSelected
                                                  ? AdminTheme.primaryPurple
                                                  : Colors.white10,
                                          borderRadius: BorderRadius.circular(
                                            AdminTheme.radiusSm,
                                          ),
                                        ),
                                        child: Text(
                                          icon,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AdminTheme.spacingLg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminTheme.successGreen,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          onPressed: () async {
                            final newItem = BannerItem(
                              id: '',
                              title: _titleController.text,
                              subtitle: _subtitleController.text,
                              themeId: _selectedThemeId,
                              actionTarget: _targetController.text,
                              icon: _selectedIcon,
                              isActive: true,
                            );
                            await ContentService().addBanner(newItem);
                            if (mounted) Navigator.pop(context);
                          },
                          child: const Text('Publish to App'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Live Preview Side
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(AdminTheme.radiusXl),
                  ),
                ),
                padding: const EdgeInsets.all(AdminTheme.spacingXl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'APP PREVIEW',
                      style: AdminTheme.labelMedium.copyWith(
                        color: AdminTheme.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // The actual banner preview
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 500),
                      tween: Tween<double>(begin: 0.9, end: 1.0),
                      builder: (context, double scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: double.infinity,
                            height: 180,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: selectedTheme.gradientColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: selectedTheme.gradientColors.first
                                      .withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (_selectedIcon != null)
                                      Text(
                                        _selectedIcon!,
                                        style: const TextStyle(fontSize: 32),
                                      ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white24,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'NEW',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  _titleController.text.isEmpty
                                      ? 'Awesome Offer'
                                      : _titleController.text,
                                  style: TextStyle(
                                    color: selectedTheme.textColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _subtitleController.text.isEmpty
                                      ? 'Tap to explore'
                                      : _subtitleController.text,
                                  style: TextStyle(
                                    color: selectedTheme.textColor.withOpacity(
                                      0.8,
                                    ),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'This is how users will see it on home screen.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AdminTheme.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AdminTheme.labelMedium),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AdminTheme.textTertiary.withOpacity(0.5),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
              borderSide: BorderSide(
                color: AdminTheme.borderColor.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileMockupPreview extends StatelessWidget {
  const _MobileMockupPreview();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 220,
              height: 440,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white24, width: 8),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mock Status Bar
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '01:30',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.signal_cellular_alt_rounded,
                            color: Colors.white,
                            size: 10,
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.battery_std_rounded,
                            color: Colors.white,
                            size: 10,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Mock Top Creators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      4,
                      (index) => CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white12,
                        child: Icon(
                          Icons.person,
                          color: Colors.white38,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Content Banner Slot
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366f1), Color(0xFFa855f7)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎉 WELCOME',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Get started with Strame',
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Grid items
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: List.generate(
                        4,
                        (index) => Container(
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Home Screen Layout',
              style: AdminTheme.labelMedium.copyWith(
                color: AdminTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
