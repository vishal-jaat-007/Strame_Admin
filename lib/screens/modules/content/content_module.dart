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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;
    final isTablet = screenWidth >= 900 && screenWidth < 1200;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context),

          const SizedBox(height: AdminTheme.spacingXl),

          // Main Section Split
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBannersSection(),
                const SizedBox(height: AdminTheme.spacingXl),
                _buildPreviewSection(),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active Banners List
                Expanded(flex: 2, child: _buildBannersSection()),

                const SizedBox(width: AdminTheme.spacingXl),

                // Preview & Guide Section
                Expanded(flex: isTablet ? 1 : 1, child: _buildPreviewSection()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBannersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Active Mobile Banners', style: AdminTheme.headlineSmall),
        const SizedBox(height: AdminTheme.spacingMd),
        StreamBuilder<List<BannerItem>>(
          stream: _contentService.getBanners(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final banners = snapshot.data ?? [];
            if (banners.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: banners.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _BannerListItem(
                  banner: banners[index],
                  onToggle:
                      () => _contentService.toggleBanner(
                        banners[index].id,
                        banners[index].isActive,
                      ),
                  onDelete:
                      () => _contentService.deleteBanner(banners[index].id),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Live Preview Guide', style: AdminTheme.headlineSmall),
        const SizedBox(height: AdminTheme.spacingMd),
        const _MobileMockupPreview(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Content & Banners', style: AdminTheme.headlineMedium),
          const SizedBox(height: AdminTheme.spacingXs),
          Text(
            'Design and manage 50+ animated themes.',
            style: AdminTheme.bodyMedium.copyWith(
              color: AdminTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AdminTheme.spacingMd),
          ElevatedButton.icon(
            onPressed: () => _showManagementDialog(context),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Create Banner'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.primaryPurple,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
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
        ),
        const SizedBox(width: 16),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final theme = bannerThemes.firstWhere(
      (t) => t.id == banner.themeId,
      orElse: () => bannerThemes.first,
    );

    return GlassCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child:
            isMobile
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: theme.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AdminTheme.radiusLg),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (banner.icon != null)
                            Text(
                              banner.icon!,
                              style: const TextStyle(fontSize: 20),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            banner.title,
                            style: TextStyle(
                              color: theme.textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Target: ${banner.actionTarget}',
                              style: AdminTheme.labelSmall.copyWith(
                                color: AdminTheme.textSecondary,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value: banner.isActive,
                                  onChanged: (_) => onToggle(),
                                  activeColor: AdminTheme.successGreen,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_sweep_rounded,
                                  color: AdminTheme.errorRed,
                                  size: 20,
                                ),
                                onPressed: onDelete,
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                )
                : Row(
                  children: [
                    Container(
                      width: screenWidth < 1100 ? 180 : 240,
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
                            Text(
                              banner.icon!,
                              style: const TextStyle(fontSize: 24),
                            ),
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
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Target: ${banner.actionTarget}',
                                    style: AdminTheme.labelSmall.copyWith(
                                      color: AdminTheme.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobileDialog = screenWidth < 950;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: isMobileDialog ? 500 : 900,
        height: (isMobileDialog ? (screenWidth < 600 ? 800 : 700) : 700)
            .toDouble()
            .clamp(0.0, screenHeight * 0.9),
        decoration: BoxDecoration(
          color: AdminTheme.cardDark,
          borderRadius: BorderRadius.circular(AdminTheme.radiusXl),
          border: Border.all(color: AdminTheme.borderColor),
        ),
        child:
            isMobileDialog
                ? SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSettingsSide(context, selectedTheme),
                      const Divider(color: AdminTheme.borderColor),
                      _buildPreviewSide(context, selectedTheme),
                    ],
                  ),
                )
                : Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildSettingsSide(context, selectedTheme),
                    ),
                    Expanded(
                      flex: 2,
                      child: _buildPreviewSide(context, selectedTheme),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildSettingsSide(
    BuildContext context,
    BannerThemeData selectedTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AdminTheme.spacingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Banner Designer', style: AdminTheme.headlineSmall),
          const SizedBox(height: AdminTheme.spacingLg),
          _buildInputField(
            'Main Title',
            'e.g. Get 50% Bonus',
            _titleController,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            'Subtitle',
            'e.g. Limited offer',
            _subtitleController,
          ),
          const SizedBox(height: 16),
          _buildInputField('Target', 'e.g. /wallet', _targetController),
          const SizedBox(height: 24),
          Text('Select Theme', style: AdminTheme.labelMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: bannerThemes.length,
              itemBuilder: (context, index) {
                final theme = bannerThemes[index];
                final isSelected = theme.id == _selectedThemeId;
                return GestureDetector(
                  onTap: () => setState(() => _selectedThemeId = theme.id),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: theme.gradientColors),
                      borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                      border:
                          isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text('Select Icon', style: AdminTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _icons.map((icon) {
                  final isSelected = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
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
                      child: Text(icon, style: const TextStyle(fontSize: 20)),
                    ),
                  );
                }).toList(),
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
                child: const Text('Publish'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSide(
    BuildContext context,
    BannerThemeData selectedTheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: const BorderRadius.horizontal(
          right: Radius.circular(AdminTheme.radiusXl),
        ),
      ),
      padding: const EdgeInsets.all(AdminTheme.spacingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('APP PREVIEW', style: AdminTheme.labelSmall),
          const SizedBox(height: 32),
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 500),
            tween: Tween<double>(begin: 0.9, end: 1.0),
            builder: (context, double scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 180),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: selectedTheme.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedIcon != null)
                        Text(
                          _selectedIcon!,
                          style: const TextStyle(fontSize: 32),
                        ),
                      const SizedBox(height: 20),
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
                          color: selectedTheme.textColor.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
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
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
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
      child: Center(
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
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          4,
                          (index) => const CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
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
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
              Text('Home Screen Layout', style: AdminTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}


