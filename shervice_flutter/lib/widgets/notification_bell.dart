import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constant.dart';

class NotificationBell extends StatefulWidget {
  final String role;
  final String userId;
  final String userName;
  final String companyName;

  const NotificationBell({
    super.key,
    required this.role,
    required this.userId,
    required this.userName,
    this.companyName = 'Internal', required int iconSize,
  });

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class NotificationEntry {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final int? relatedTripId;
  final String sourceTag;
  bool isRead;

  NotificationEntry({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.relatedTripId,
    this.sourceTag = 'system',
    this.isRead = false,
  });

  factory NotificationEntry.fromJson(Map<String, dynamic> json) {
    final jsonSource = (json['source_tag'] as String?)?.trim();
    final sourceRole = (json['target_role'] as String?)?.trim();
    final sourceCompany = (json['target_company'] as String?)?.trim();
    final inferredSource = (jsonSource?.isNotEmpty == true)
        ? jsonSource!
        : (sourceRole?.isNotEmpty == true
              ? sourceRole!
              : ((sourceCompany?.isNotEmpty == true)
                    ? sourceCompany!
                    : 'system'));

    return NotificationEntry(
      id: json['notification_id'].toString(),
      title: json['title'] ?? 'Notification',
      message: json['message'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : DateTime.now(),
      relatedTripId: json['related_trip_id'],
      sourceTag: inferredSource,
      isRead: json['is_read'] ?? false,
    );
  }
}

class _NotificationBellState extends State<NotificationBell> {
  bool _isLoading = false;
  List<NotificationEntry> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse('$backendUrl/notifications').replace(
        queryParameters: {
          'user_id': widget.userId,
          'role': widget.role,
          'company': widget.companyName,
        },
      );

      debugPrint('🔔 Fetching notifications from: $uri');
      final response = await http.get(uri);
      debugPrint(
        '🔔 notifications fetch status: ${response.statusCode} body: ${response.body}',
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> data = body['data'];
          if (mounted) {
            setState(() {
              _notifications = data
                  .map((json) => NotificationEntry.fromJson(json))
                  .toList();
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch notifications: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(
    NotificationEntry entry, [
    StateSetter? dialogSetState,
  ]) async {
    if (entry.isRead) return;

    setState(() => entry.isRead = true);
    dialogSetState?.call(() {});

    try {
      await http.put(
        Uri.parse('$backendUrl/notifications/${entry.id}/read'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      debugPrint('Failed to sync read status: $e');
    }
  }

  void _showNotificationDetails(
    NotificationEntry notification,
    StateSetter dialogSetState,
  ) {
    _markAsRead(notification, dialogSetState);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Expanded(child: Text(notification.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 12),
            Chip(
              label: Text(
                'Source: ${notification.sourceTag}',
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: Colors.grey.shade100,
            ),
            const SizedBox(height: 12),
            Text(
              'Received: ${notification.createdAt.toString().substring(0, 16)}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            if (notification.relatedTripId != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              Text(
                'Trip Reference ID: #${notification.relatedTripId}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNotificationPanel() {
    final topPadding = MediaQuery.of(context).padding.top + 8;
    final maxWidth = MediaQuery.of(context).size.width * 0.95;
    final panelWidth = maxWidth > 420 ? 420.0 : maxWidth;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notifications',
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.only(top: topPadding, right: 12),
              child: Material(
                color: Colors.transparent,
                child: StatefulBuilder(
                  builder: (context, dialogSetState) {
                    return Container(
                      width: panelWidth,
                      height: MediaQuery.of(context).size.height * 0.72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(46),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: DefaultTabController(
                        length: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.notifications,
                                  color: Colors.blue,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${widget.role} Notifications',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () async {
                                    await _fetchNotifications();
                                    dialogSetState(() {});
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: TabBar(
                                labelColor: Colors.blue.shade800,
                                unselectedLabelColor: Colors.grey.shade600,
                                indicatorColor: Colors.blue.shade800,
                                tabs: const [
                                  Tab(text: 'All'),
                                  Tab(text: 'Unread'),
                                  Tab(text: 'Read'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _buildNotificationTab('all', dialogSetState),
                                  _buildNotificationTab(
                                    'unread',
                                    dialogSetState,
                                  ),
                                  _buildNotificationTab('read', dialogSetState),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationTab(String filter, [StateSetter? dialogSetState]) {
    final items = _notifications.where((item) {
      if (filter == 'all') return true;
      if (filter == 'unread') return !item.isRead;
      return item.isRead;
    }).toList();

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (items.isEmpty) {
      return Center(
        child: Text(
          filter == 'unread'
              ? 'No unread notifications.'
              : 'No notifications here.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final notification = items[index];
        return ListTile(
          onTap: () => _showNotificationDetails(notification, dialogSetState!),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 4,
          ),
          leading: CircleAvatar(
            backgroundColor: notification.isRead
                ? Colors.grey.shade200
                : Colors.blue.shade50,
            child: Icon(
              notification.isRead
                  ? Icons.mark_email_read
                  : Icons.mark_email_unread,
              color: notification.isRead
                  ? Colors.grey.shade700
                  : Colors.blue.shade700,
              size: 18,
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead
                  ? FontWeight.normal
                  : FontWeight.bold,
              color: notification.isRead ? Colors.grey.shade800 : Colors.black,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                notification.sourceTag,
                style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
              ),
            ],
          ),
          tileColor: notification.isRead
              ? Colors.transparent
              : Colors.blue.shade50.withAlpha(38),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((item) => !item.isRead).length;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.grey, size: 32), // 👈 enlarged
            onPressed: _showNotificationPanel,
          ),
          if (unreadCount > 0)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}