import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  Set<String> _seenIds = {};

  @override
  void initState() {
    super.initState();
    _loadSeenNotifications();
  }

  Future<void> _loadSeenNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _seenIds = prefs.getStringList('seen_notification_ids')?.toSet() ?? {};
    });
  }

  Future<void> _markAsSeen(String id) async {
    if (_seenIds.contains(id)) return;

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _seenIds.add(id);
    });
    await prefs.setStringList('seen_notification_ids', _seenIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.green));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notifications:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text("No notifications yet",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;
              final id = doc.id;
              final isSeen = _seenIds.contains(id);

              final timestamp = data['timestamp'] as Timestamp?;
              final timeStr = timestamp != null
                  ? DateFormat('MMM dd, hh:mm a').format(timestamp.toDate())
                  : '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                elevation: isSeen ? 0 : 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: isSeen
                    ? (isDark ? Colors.grey.shade900 : Colors.grey.shade50)
                    : (isDark ? const Color(0xFF0B3D2E) : Colors.white),
                child: ListTile(
                  onTap: () => _markAsSeen(id),
                  leading: CircleAvatar(
                    backgroundColor:
                        _getIconColor(data['type']).withValues(alpha: 0.1),
                    child: Icon(_getIcon(data['type']),
                        color: _getIconColor(data['type'])),
                  ),
                  title: Text(
                    data['title'] ?? 'Notification',
                    style: TextStyle(
                      fontWeight: isSeen ? FontWeight.normal : FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(data['body'] ?? ''),
                      const SizedBox(height: 6),
                      Text(
                        timeStr,
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  trailing: !isSeen
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'event':
        return Icons.event;
      case 'collaboration':
        return Icons.groups;
      case 'lost_found':
        return Icons.search;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String? type) {
    switch (type) {
      case 'event':
        return Colors.orange;
      case 'collaboration':
        return Colors.blue;
      case 'lost_found':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
