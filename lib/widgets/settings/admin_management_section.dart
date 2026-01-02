import 'package:flutter/material.dart';
import '../../theme/admin_theme.dart';
import '../../services/admin_auth_service.dart';
import '../../models/admin_user.dart';
import '../common/glass_card.dart';
import '../common/user_avatar.dart';

class AdminManagementSection extends StatefulWidget {
  final VoidCallback onBack;

  const AdminManagementSection({super.key, required this.onBack});

  @override
  State<AdminManagementSection> createState() => _AdminManagementSectionState();
}

class _AdminManagementSectionState extends State<AdminManagementSection> {
  final AdminAuthService _authService = AdminAuthService();
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _isAdding = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService.createAdmin(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin added successfully')),
        );
        setState(() {
          _isAdding = false;
          _emailController.clear();
          _passwordController.clear();
          _nameController.clear();
        });
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAdmin(AdminUser user) async {
    final curUser = _authService.currentUser;
    if (curUser?.uid == user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot delete your own account')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AdminTheme.surfaceDark,
            title: const Text(
              'Delete Admin',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to remove ${user.name ?? user.email} as an admin?',
              style: const TextStyle(color: AdminTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: AdminTheme.errorRed,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _authService.deleteAdmin(user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin removed successfully')),
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                    onPressed: widget.onBack,
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AdminTheme.primaryPurple,
                  ),
                  const SizedBox(width: 12),
                  Text('Admins', style: AdminTheme.headlineSmall),
                ],
              ),
              if (!_isAdding)
                Padding(
                  padding: const EdgeInsets.only(
                    left: AdminTheme.spacingMd,
                    top: AdminTheme.spacingMd,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _isAdding = true),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Admin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.primaryPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                  ),
                ),
            ],
          )
        else
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: widget.onBack,
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.admin_panel_settings_rounded,
                color: AdminTheme.primaryPurple,
              ),
              const SizedBox(width: 12),
              Text('Manage Administrators', style: AdminTheme.headlineSmall),
              const Spacer(),
              if (!_isAdding)
                ElevatedButton.icon(
                  onPressed: () => setState(() => _isAdding = true),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Admin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: AdminTheme.spacingLg),

        // Content
        if (_isAdding) _buildAddForm() else _buildAdminList(),

        if (_isAdding) ...[
          const SizedBox(height: AdminTheme.spacingLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _isAdding = false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _addAdmin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text('Save Admin Account'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAdminList() {
    return StreamBuilder<List<AdminUser>>(
      stream: _authService.getAdminsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AdminTheme.spacing3Xl),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final admins = snapshot.data ?? [];
        if (admins.isEmpty) {
          return GlassCard(
            padding: const EdgeInsets.all(AdminTheme.spacingLg),
            child: const Center(
              child: Text(
                'No other administrators found.',
                style: TextStyle(color: AdminTheme.textSecondary),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: admins.length,
          separatorBuilder:
              (context, index) => const SizedBox(height: AdminTheme.spacingMd),
          itemBuilder: (context, index) {
            final admin = admins[index];
            final isMe = _authService.currentUser?.uid == admin.uid;

            return GlassCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: UserAvatar(
                  photoUrl: admin.photoUrl ?? '',
                  name: admin.name ?? admin.email,
                  radius: 20,
                ),
                title: Text(
                  admin.name ?? 'Admin',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${admin.email}${isMe ? " (You)" : ""}',
                  style: TextStyle(
                    color: AdminTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: isMe ? AdminTheme.textTertiary : AdminTheme.errorRed,
                    size: 20,
                  ),
                  onPressed: isMe ? null : () => _deleteAdmin(admin),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddForm() {
    return GlassCard(
      padding: const EdgeInsets.all(AdminTheme.spacingLg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create New Admin Account',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This will create a new login credential in the system.',
              style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),

            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter admin name',
              icon: Icons.person_rounded,
              validator: (v) => v!.isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 20),

            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              hint: 'admin@strame.com',
              icon: Icons.email_rounded,
              validator:
                  (v) =>
                      v!.isEmpty || !v.contains('@') ? 'Invalid email' : null,
            ),
            const SizedBox(height: 20),

            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Set a secure password (min 6 chars)',
              icon: Icons.lock_rounded,
              isPassword: true,
              validator: (v) => v!.length < 6 ? 'Password too short' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AdminTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AdminTheme.textTertiary),
            prefixIcon: Icon(icon, color: AdminTheme.primaryPurple, size: 20),
            filled: true,
            fillColor: Colors.black.withOpacity(0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
              borderSide: BorderSide(
                color: AdminTheme.borderColor.withOpacity(0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
              borderSide: BorderSide(
                color: AdminTheme.borderColor.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
              borderSide: const BorderSide(color: AdminTheme.primaryPurple),
            ),
            errorStyle: const TextStyle(color: AdminTheme.errorRed),
          ),
        ),
      ],
    );
  }
}
