import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../theme/admin_theme.dart';
import '../../../services/app_config_service.dart';
import '../../../widgets/common/glass_card.dart';

class MonetizationModule extends StatefulWidget {
  const MonetizationModule({super.key});

  @override
  State<MonetizationModule> createState() => _MonetizationModuleState();
}

class _MonetizationModuleState extends State<MonetizationModule>
    with SingleTickerProviderStateMixin {
  final AppConfigService _configService = AppConfigService();
  late TabController _tabController;
  final _settingsFormKey = GlobalKey<FormState>();

  // Controllers for settings
  final _voiceRateUserController = TextEditingController();
  final _voiceRateCreatorController = TextEditingController();
  final _videoRateUserController = TextEditingController();
  final _videoRateCreatorController = TextEditingController();
  final _chatRateController = TextEditingController();
  final _commissionController = TextEditingController();

  bool _isSavingSettings = false;
  Map<String, dynamic>? _lastSettings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _voiceRateUserController.dispose();
    _voiceRateCreatorController.dispose();
    _videoRateUserController.dispose();
    _videoRateCreatorController.dispose();
    _chatRateController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_settingsFormKey.currentState!.validate()) return;

    setState(() => _isSavingSettings = true);
    try {
      await _configService.updateMonetizationSettings({
        'voiceRateUserDebit': int.parse(_voiceRateUserController.text.trim()),
        'voiceRateCreatorCredit': int.parse(
          _voiceRateCreatorController.text.trim(),
        ),
        'videoRateUserDebit': int.parse(_videoRateUserController.text.trim()),
        'videoRateCreatorCredit': int.parse(
          _videoRateCreatorController.text.trim(),
        ),
        'chatCostPerMessage': int.parse(_chatRateController.text.trim()),
        'platformCommission': int.parse(_commissionController.text.trim()),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Monetization settings updated successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AdminTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingSettings = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? AdminTheme.spacingMd : AdminTheme.spacingLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Monetization & Pricing',
                  style:
                      isMobile
                          ? AdminTheme.headlineSmall
                          : AdminTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: AdminTheme.spacingXs),
              Text(
                'Configure call rates, creator earnings, and coin package prices.',
                style: AdminTheme.bodyMedium.copyWith(
                  color: AdminTheme.textSecondary,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AdminTheme.spacingLg),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          labelColor: AdminTheme.primaryPurple,
          unselectedLabelColor: AdminTheme.textSecondary,
          indicatorColor: AdminTheme.primaryPurple,
          tabs: const [
            Tab(text: 'Call Rates & Earnings'),
            Tab(text: 'Coin Sales (Coin Store)'),
          ],
        ),
        const SizedBox(height: AdminTheme.spacingLg),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildRatesTab(), _buildCoinStoreTab()],
          ),
        ),
      ],
    );
  }

  Widget _buildRatesTab() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _configService.getMonetizationSettings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final settings = snapshot.data ?? {};

        // Populate controllers if data changed
        if (!mapEquals(settings, _lastSettings)) {
          _voiceRateUserController.text =
              (settings['voiceRateUserDebit'] ?? 12).toString();
          _voiceRateCreatorController.text =
              (settings['voiceRateCreatorCredit'] ?? 6).toString();
          _videoRateUserController.text =
              (settings['videoRateUserDebit'] ?? 48).toString();
          _videoRateCreatorController.text =
              (settings['videoRateCreatorCredit'] ?? 20).toString();
          _chatRateController.text =
              (settings['chatCostPerMessage'] ?? 2).toString();
          _commissionController.text =
              (settings['platformCommission'] ?? 50).toString();

          _lastSettings = settings;
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 900;
        final isVerySmall = screenWidth < 400;

        return SingleChildScrollView(
          padding: EdgeInsets.all(
            isVerySmall ? AdminTheme.spacingMd : AdminTheme.spacingLg,
          ),
          child: Form(
            key: _settingsFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMobile) ...[
                  _buildRateSection('Voice Call Settings', Icons.mic_rounded, [
                    _buildNumberField(
                      _voiceRateUserController,
                      'User Cost (Coins/min)',
                      'e.g. 12',
                    ),
                    _buildNumberField(
                      _voiceRateCreatorController,
                      'Creator Earnings (Coins/min)',
                      'e.g. 6',
                    ),
                  ]),
                  const SizedBox(height: AdminTheme.spacingLg),
                  _buildRateSection(
                    'Video Call Settings',
                    Icons.videocam_rounded,
                    [
                      _buildNumberField(
                        _videoRateUserController,
                        'User Cost (Coins/min)',
                        'e.g. 48',
                      ),
                      _buildNumberField(
                        _videoRateCreatorController,
                        'Creator Earnings (Coins/min)',
                        'e.g. 20',
                      ),
                    ],
                  ),
                  const SizedBox(height: AdminTheme.spacingLg),
                  _buildRateSection(
                    'Chat & Commission',
                    Icons.chat_bubble_rounded,
                    [
                      _buildNumberField(
                        _chatRateController,
                        'Chat Cost (Coins/Message)',
                        'e.g. 2',
                      ),
                      _buildNumberField(
                        _commissionController,
                        'Platform Commission (%)',
                        'e.g. 50',
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildRateSection(
                          'Voice Call Settings',
                          Icons.mic_rounded,
                          [
                            _buildNumberField(
                              _voiceRateUserController,
                              'User Cost (Coins/min)',
                              'e.g. 12',
                            ),
                            _buildNumberField(
                              _voiceRateCreatorController,
                              'Creator Earnings (Coins/min)',
                              'e.g. 6',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AdminTheme.spacingLg),
                      Expanded(
                        child: _buildRateSection(
                          'Video Call Settings',
                          Icons.videocam_rounded,
                          [
                            _buildNumberField(
                              _videoRateUserController,
                              'User Cost (Coins/min)',
                              'e.g. 48',
                            ),
                            _buildNumberField(
                              _videoRateCreatorController,
                              'Creator Earnings (Coins/min)',
                              'e.g. 20',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AdminTheme.spacingLg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildRateSection(
                          'Chat & Commission',
                          Icons.chat_bubble_rounded,
                          [
                            _buildNumberField(
                              _chatRateController,
                              'Chat Cost (Coins/Message)',
                              'e.g. 2',
                            ),
                            _buildNumberField(
                              _commissionController,
                              'Platform Commission (%)',
                              'e.g. 50',
                            ),
                          ],
                        ),
                      ),
                      const Expanded(
                        child: SizedBox(),
                      ), // Placeholder to keep layout balanced
                    ],
                  ),
                ],
                const SizedBox(height: AdminTheme.spacingXl),
                SizedBox(
                  width: isVerySmall ? double.infinity : 250,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSavingSettings ? null : _saveSettings,
                    icon:
                        _isSavingSettings
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.save_rounded),
                    label: const Text('Save Global Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.primaryPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRateSection(String title, IconData icon, List<Widget> children) {
    return GlassCard(
      padding: const EdgeInsets.all(AdminTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(icon, color: AdminTheme.primaryPurple, size: 20),
                const SizedBox(width: 8),
                Text(title, style: AdminTheme.headlineSmall),
              ],
            ),
          ),
          const Divider(height: 32, color: AdminTheme.borderColor),
          ...children.map(
            (child) => Padding(
              padding: const EdgeInsets.only(bottom: AdminTheme.spacingMd),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField(
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.black26,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Value required';
        if (int.tryParse(value.trim()) == null) return 'Must be a number';
        return null;
      },
    );
  }

  Widget _buildCoinStoreTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isVerySmall = screenWidth < 400;

    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isVerySmall ? AdminTheme.spacingMd : AdminTheme.spacingLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Coin Packages',
                    style:
                        isMobile
                            ? AdminTheme.headlineSmall
                            : AdminTheme.headlineMedium,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isVerySmall)
                IconButton(
                  onPressed: () => _showAddPackageDialog(),
                  icon: const Icon(Icons.add_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AdminTheme.successGreen,
                    foregroundColor: Colors.white,
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => _showAddPackageDialog(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Package'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.successGreen,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AdminTheme.spacingLg),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _configService.getCoinPackages(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final packages = snapshot.data ?? [];
              if (packages.isEmpty) {
                return const Center(
                  child: Text(
                    'No coin packages defined yet.',
                    style: TextStyle(color: AdminTheme.textSecondary),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final isMobile = screenWidth < 600;

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isMobile ? 1 : (screenWidth < 1100 ? 2 : 3),
                    mainAxisSpacing: AdminTheme.spacingLg,
                    crossAxisSpacing: AdminTheme.spacingLg,
                    childAspectRatio: isMobile ? 1.0 : 0.85,
                    children:
                        packages.map((pkg) => _buildPackageCard(pkg)).toList(),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> pkg) {
    return GlassCard(
      padding: const EdgeInsets.all(AdminTheme.spacingLg),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.monetization_on_rounded,
                color: Colors.amber,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${pkg['coinAmount']} Coins',
              style: AdminTheme.headlineMedium.copyWith(color: Colors.amber),
            ),
            const SizedBox(height: 8),
            Text('Price: ₹${pkg['price']}', style: AdminTheme.headlineSmall),
            if (pkg['bonusAmount'] != null && pkg['bonusAmount'] > 0) ...[
              const SizedBox(height: 4),
              Text(
                '+ ${pkg['bonusAmount']} Bonus Coins',
                style: const TextStyle(
                  color: AdminTheme.successGreen,
                  fontSize: 12,
                ),
              ),
            ],
            const Divider(height: 32, color: AdminTheme.borderColor),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () => _showAddPackageDialog(package: pkg),
                  icon: const Icon(
                    Icons.edit_rounded,
                    color: AdminTheme.primaryPurple,
                  ),
                ),
                IconButton(
                  onPressed: () => _configService.deleteCoinPackage(pkg['id']),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AdminTheme.errorRed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPackageDialog({Map<String, dynamic>? package}) {
    final coinAmountController = TextEditingController(
      text: package != null ? package['coinAmount'].toString() : '',
    );
    final priceController = TextEditingController(
      text: package != null ? package['price'].toString() : '',
    );
    final bonusController = TextEditingController(
      text: package != null ? (package['bonusAmount'] ?? 0).toString() : '0',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AdminTheme.cardDark,
            title: Text(
              package == null ? 'Add Coin Package' : 'Edit Package',
              style: const TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNumberField(
                    coinAmountController,
                    'Coin Amount',
                    'e.g. 1000',
                  ),
                  const SizedBox(height: 16),
                  _buildNumberField(priceController, 'Price (₹)', 'e.g. 199'),
                  const SizedBox(height: 16),
                  _buildNumberField(
                    bonusController,
                    'Bonus Amount (Optional)',
                    '0',
                  ),
                ],
              ),
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
                  _configService.upsertCoinPackage(package?['id'], {
                    'coinAmount':
                        int.tryParse(
                          coinAmountController.text.replaceAll(
                            RegExp(r'[^0-9]'),
                            '',
                          ),
                        ) ??
                        0,
                    'price':
                        double.tryParse(
                          priceController.text.replaceAll(
                            RegExp(r'[^0-9.]'),
                            '',
                          ),
                        ) ??
                        0.0,
                    'bonusAmount':
                        int.tryParse(
                          bonusController.text.replaceAll(
                            RegExp(r'[^0-9]'),
                            '',
                          ),
                        ) ??
                        0,
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primaryPurple,
                ),
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }
}
