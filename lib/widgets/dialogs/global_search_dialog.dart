import 'package:flutter/material.dart';
import '../../theme/admin_theme.dart';
import '../../services/search_service.dart';
import '../../models/app_user.dart';
import '../../models/navigation_item.dart';
import '../common/glass_card.dart';
import '../common/user_avatar.dart';

class GlobalSearchDialog extends StatefulWidget {
  final ValueChanged<NavigationItem> onNavItemChanged;

  const GlobalSearchDialog({super.key, required this.onNavItemChanged});

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  final SearchService _searchService = SearchService();
  final TextEditingController _controller = TextEditingController();
  List<AppUser> _results = [];
  bool _isLoading = false;

  void _onSearch(String query) async {
    if (query.length < 2) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await _searchService.searchUsers(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(AdminTheme.spacingLg),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(color: AdminTheme.textPrimary),
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search for users or creators...',
                hintStyle: const TextStyle(color: AdminTheme.textSecondary),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AdminTheme.primaryPurple,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                  borderSide: const BorderSide(color: AdminTheme.borderColor),
                ),
                filled: true,
                fillColor: Colors.black26,
              ),
            ),
            const SizedBox(height: AdminTheme.spacingLg),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _results.isEmpty
                      ? Center(
                        child: Text(
                          _controller.text.isEmpty
                              ? 'Type to search...'
                              : 'No results found',
                          style: const TextStyle(
                            color: AdminTheme.textSecondary,
                          ),
                        ),
                      )
                      : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder:
                            (context, index) =>
                                const SizedBox(height: AdminTheme.spacingMd),
                        itemBuilder: (context, index) {
                          final user = _results[index];
                          final joinDate =
                              "${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}";

                          return GlassCard(
                            padding: EdgeInsets.zero,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AdminTheme.spacingMd,
                                vertical: AdminTheme.spacingXs,
                              ),
                              leading: UserAvatar(
                                photoUrl: user.photoUrl,
                                name: user.name,
                                radius: 24,
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      color: AdminTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (user.isCreator
                                              ? AdminTheme.accentBlue
                                              : AdminTheme.primaryPurple)
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: (user.isCreator
                                                ? AdminTheme.accentBlue
                                                : AdminTheme.primaryPurple)
                                            .withOpacity(0.3),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      user.role.toUpperCase(),
                                      style: TextStyle(
                                        color:
                                            user.isCreator
                                                ? AdminTheme.accentBlue
                                                : AdminTheme.primaryPurple,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    user.email,
                                    style: const TextStyle(
                                      color: AdminTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "UID: ${user.uid} • Joined: $joinDate",
                                    style: const TextStyle(
                                      color: AdminTheme.textTertiary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: AdminTheme.textSecondary,
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                widget.onNavItemChanged(
                                  user.isCreator
                                      ? NavigationItem.creators
                                      : NavigationItem.users,
                                );
                              },
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
