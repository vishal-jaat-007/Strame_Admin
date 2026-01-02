import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../theme/admin_theme.dart';
import '../../../services/notification_service.dart';
import '../../../services/user_service.dart';
import '../../../models/app_user.dart';
import '../../../widgets/common/glass_card.dart';

class NotificationsModule extends StatefulWidget {
  const NotificationsModule({super.key});

  @override
  State<NotificationsModule> createState() => _NotificationsModuleState();
}

class _NotificationsModuleState extends State<NotificationsModule> {
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  String? _uploadedImageUrl;
  bool _isUploading = false;
  bool _isSending = false;

  String _targetType = 'broadcast'; // 'broadcast' or 'specific'
  final List<AppUser> _selectedUsers = [];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isUploading = true);

      final file = result.files.first;
      final fileName =
          'notifications/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);

      TaskSnapshot uploadTask;
      if (kIsWeb) {
        uploadTask = await storageRef.putData(file.bytes!);
      } else {
        uploadTask = await storageRef.putData(file.bytes!);
      }

      final url = await uploadTask.ref.getDownloadURL();
      setState(() {
        _uploadedImageUrl = url;
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AdminTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    if (_targetType == 'specific' && _selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one user'),
          backgroundColor: AdminTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final String type =
          _targetType == 'broadcast'
              ? 'broadcast'
              : (_selectedUsers.length > 1 ? 'list' : 'single');

      await _notificationService.sendNotification(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        imageUrl: _uploadedImageUrl,
        targetType: type,
        targetUid: _selectedUsers.isNotEmpty ? _selectedUsers.first.uid : null,
        targetUids: _selectedUsers.map((u) => u.uid).toList(),
        targetName:
            _selectedUsers.length == 1
                ? _selectedUsers.first.name
                : (_selectedUsers.length > 1
                    ? '${_selectedUsers.length} Users'
                    : null),
        receiverType:
            _selectedUsers.isNotEmpty
                ? (_selectedUsers.first.role == 'creator' ? 'creator' : 'user')
                : 'user',
      );

      if (mounted) {
        _titleController.clear();
        _bodyController.clear();
        setState(() {
          _uploadedImageUrl = null;
          _selectedUsers.clear();
          _targetType = 'broadcast';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notification request sent! Check history for status.',
            ),
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
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Push Notifications', style: AdminTheme.headlineMedium),
          const SizedBox(height: AdminTheme.spacingXs),
          Text(
            'Broadcast messages to all app users.',
            style: AdminTheme.bodyMedium.copyWith(
              color: AdminTheme.textSecondary,
            ),
          ),

          const SizedBox(height: AdminTheme.spacingLg),

          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildComposeForm(),
                const SizedBox(height: AdminTheme.spacingXl),
                _buildHistorySection(),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compose Form
                Expanded(flex: 2, child: _buildComposeForm()),

                const SizedBox(width: AdminTheme.spacingLg),

                // History / Stats
                Expanded(flex: 3, child: _buildHistorySection()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildComposeForm() {
    return GlassCard(
      padding: const EdgeInsets.all(AdminTheme.spacingLg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Compose New Notification', style: AdminTheme.headlineSmall),
            const SizedBox(height: AdminTheme.spacingLg),
            const Text(
              'Target Audience',
              style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTargetOption(
                  'broadcast',
                  'All Users',
                  Icons.groups_rounded,
                ),
                const SizedBox(width: 12),
                _buildTargetOption(
                  'specific',
                  'User List',
                  Icons.person_add_rounded,
                ),
              ],
            ),
            const SizedBox(height: AdminTheme.spacingLg),

            if (_targetType == 'specific') ...[
              _buildUserSelector(),
              if (_selectedUsers.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      _selectedUsers
                          .map(
                            (user) => Chip(
                              avatar: CircleAvatar(
                                radius: 12,
                                backgroundImage:
                                    user.photoUrl != null
                                        ? NetworkImage(user.photoUrl!)
                                        : null,
                                child:
                                    user.photoUrl == null
                                        ? Text(
                                          user.name[0].toUpperCase(),
                                          style: const TextStyle(fontSize: 10),
                                        )
                                        : null,
                              ),
                              label: Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                              onDeleted:
                                  () => setState(
                                    () => _selectedUsers.remove(user),
                                  ),
                              backgroundColor: AdminTheme.primaryPurple
                                  .withOpacity(0.2),
                              deleteIconColor: AdminTheme.errorRed,
                              side: BorderSide(
                                color: AdminTheme.primaryPurple.withOpacity(
                                  0.5,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
              const SizedBox(height: AdminTheme.spacingMd),
            ],

            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. New Live Event!',
              ),
              validator: (v) => v!.isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: AdminTheme.spacingMd),

            TextFormField(
              controller: _bodyController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Message Body',
                hintText: 'Enter notification message content...',
              ),
              validator: (v) => v!.isEmpty ? 'Message body is required' : null,
            ),
            const SizedBox(height: AdminTheme.spacingLg),

            _buildImageUploadSection(),

            const SizedBox(height: AdminTheme.spacingXl),

            ElevatedButton.icon(
              onPressed: _isSending ? null : _sendNotification,
              icon:
                  _isSending
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.send_rounded),
              label: Text(
                _isSending
                    ? 'Processing...'
                    : (_targetType == 'broadcast'
                        ? 'Broadcast Notification'
                        : 'Send to Selected'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.primaryPurple,
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Broadcasts', style: AdminTheme.headlineSmall),
        const SizedBox(height: AdminTheme.spacingMd),

        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _notificationService.getNotificationHistory(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final logs = snapshot.data ?? [];
            if (logs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AdminTheme.spacing2Xl),
                  child: Text(
                    'No history found',
                    style: TextStyle(color: AdminTheme.textSecondary),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder:
                  (_, __) => const SizedBox(height: AdminTheme.spacingMd),
              itemBuilder: (context, index) {
                final log = logs[index];
                final createdAt =
                    (log['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now();

                return GlassCard(
                  padding: const EdgeInsets.all(AdminTheme.spacingMd),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AdminTheme.primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AdminTheme.radiusSm,
                        ),
                      ),
                      child: Icon(() {
                        final title = (log['title'] ?? '').toLowerCase();
                        if (title.contains('missed call'))
                          return Icons.call_missed_rounded;
                        if (title.contains('incoming call'))
                          return Icons.call_received_rounded;
                        if (title.contains('call')) return Icons.call_rounded;
                        if (title.contains('welcome'))
                          return Icons.handshake_rounded;
                        if (log['type'] == 'broadcast' ||
                            log['receiverId'] == 'all' ||
                            log['target'] == 'all') {
                          return Icons.groups_rounded;
                        }
                        return Icons.person_rounded;
                      }(), color: AdminTheme.primaryPurple),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            log['title'] ?? 'No Title',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          'to: ${() {
                            final name = log['targetName'];
                            if (name != null) return name;
                            final id = log['receiverId'] ?? log['target'];
                            if (id == null) return 'User';
                            if (id == 'all') return 'All Users';
                            if (id.toString().length > 12) return '${id.toString().substring(0, 8)}...';
                            return id.toString();
                          }()}',
                          style: TextStyle(
                            color: AdminTheme.primaryPurple.withOpacity(0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log['body'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AdminTheme.textSecondary),
                        ),
                        if (log['summary'] != null || log['error'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            log['summary'] ?? 'Error: ${log['error']}',
                            style: TextStyle(
                              color:
                                  log['error'] != null
                                      ? AdminTheme.errorRed
                                      : AdminTheme.successGreen.withOpacity(
                                        0.8,
                                      ),
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, h:mm a').format(createdAt),
                          style: AdminTheme.labelSmall,
                        ),
                      ],
                    ),
                    trailing: _buildStatusBadge(log['status'] ?? 'pending'),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'completed':
      case 'sent':
      case 'success':
        color = AdminTheme.successGreen;
        break;
      case 'pending':
      case 'processing':
        color = AdminTheme.warningOrange;
        break;
      case 'error':
      case 'failed':
        color = AdminTheme.errorRed;
        break;
      default:
        color = AdminTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTargetOption(String type, String label, IconData icon) {
    final isSelected = _targetType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _targetType = type),
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AdminTheme.primaryPurple.withOpacity(0.1)
                    : Colors.transparent,
            border: Border.all(
              color:
                  isSelected
                      ? AdminTheme.primaryPurple
                      : AdminTheme.borderColor.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color:
                    isSelected
                        ? AdminTheme.primaryPurple
                        : AdminTheme.textTertiary,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color:
                      isSelected
                          ? AdminTheme.textPrimary
                          : AdminTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AdminTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        border: Border.all(color: AdminTheme.borderColor.withOpacity(0.3)),
      ),
      child: StreamBuilder<List<AppUser>>(
        stream: _userService.getAllUsers(),
        builder: (context, snapshot) {
          final users = snapshot.data ?? [];
          return Autocomplete<AppUser>(
            displayStringForOption: (user) => '',
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<AppUser>.empty();
              }
              return users.where(
                (user) =>
                    !_selectedUsers.any((s) => s.uid == user.uid) &&
                    (user.name.toLowerCase().contains(
                          textEditingValue.text.toLowerCase(),
                        ) ||
                        user.email.toLowerCase().contains(
                          textEditingValue.text.toLowerCase(),
                        )),
              );
            },
            onSelected: (user) {
              setState(() => _selectedUsers.add(user));
            },
            fieldViewBuilder: (
              context,
              controller,
              focusNode,
              onFieldSubmitted,
            ) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Search Users',
                  hintText: 'Type name or email...',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: AdminTheme.cardDark,
                  borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                  elevation: 8,
                  child: SizedBox(
                    width: 300,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final user = options.elementAt(index);
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundImage:
                                user.photoUrl != null
                                    ? NetworkImage(user.photoUrl!)
                                    : null,
                            child:
                                user.photoUrl == null
                                    ? Text(user.name[0].toUpperCase())
                                    : null,
                          ),
                          title: Text(
                            user.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            user.email,
                            style: const TextStyle(
                              color: AdminTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () => onSelected(user),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notification Image',
          style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 8),
        if (_uploadedImageUrl != null)
          Stack(
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                  image: DecorationImage(
                    image: NetworkImage(_uploadedImageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: AdminTheme.errorRed),
                  onPressed: () => setState(() => _uploadedImageUrl = null),
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                ),
              ),
            ],
          )
        else
          InkWell(
            onTap: _isUploading ? null : _pickAndUploadImage,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AdminTheme.borderColor.withOpacity(0.3),
                  style: BorderStyle.none,
                ),
                color: AdminTheme.backgroundSecondary,
                borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
              ),
              child: Center(
                child:
                    _isUploading
                        ? const CircularProgressIndicator()
                        : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_photo_alternate_rounded,
                              color: AdminTheme.textTertiary,
                              size: 30,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Upload Image',
                              style: TextStyle(
                                color: AdminTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ),
      ],
    );
  }
}
