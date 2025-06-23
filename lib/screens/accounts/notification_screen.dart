import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:heavens_connect/utils/app_theme.dart';
import '../../services/auth_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() => isLoading = true);
    final data = await _authService.getNotifications();
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      notifications = data ?? [];
      isLoading = false;
    });
    if (notifications.isNotEmpty) {
      _authService.markNotificationsAsRead();
    }
  }

  String _formatDate(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final notificationDate = DateTime(dt.year, dt.month, dt.day);
      if (notificationDate == today) return 'Today';
      if (notificationDate == today.subtract(const Duration(days: 1))) return 'Yesterday';
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return '';
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var notif in notifications) {
      final date = _formatDate(notif['created_at'] ?? '');
      grouped.putIfAbsent(date, () => []).add(notif);
    }
    return grouped;
  }

  void _deleteNotification(int index, String dateKey) {
    setState(() {
      _groupByDate()[dateKey]?.removeAt(index);
      if (_groupByDate()[dateKey]?.isEmpty ?? false) {
        _groupByDate().remove(dateKey);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = AppTheme.themeColor;
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor,
        elevation: 1,
        iconTheme: IconThemeData(color: themeColor),
        title: Text('Notifications',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: themeColor)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? Center(
        child: Text('No notifications',
            style: GoogleFonts.montserrat(color: Colors.grey)),
      )
          : RefreshIndicator(
        onRefresh: fetchNotifications,
        child: ListView(
          padding: const EdgeInsets.only(top: 10),
          children: _groupByDate().entries.map((entry) {
            final date = entry.key;
            final notifs = entry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(date,
                      style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700])),
                ),
                ...notifs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final notif = entry.value;
                  final title = notif['title'] ?? 'No Title';
                  final message = notif['message'] ?? 'No message';
                  final isRead = notif['read'] == true;
                  return Dismissible(
                    key: Key('notif-${notifications[index]['id']}'),
                    background: Container(
                      color: Colors.redAccent,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      final removed = notifications[index];
                      setState(() {
                        notifications.removeAt(index);
                      });
                      // Optionally call delete API here later
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: Icon(Icons.notifications, color: themeColor.withOpacity(0.7)),
                        title: Text(title, style: montserratTextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(message),
                        trailing: isRead
                            ? null
                            : const Icon(Icons.circle, size: 10, color: Colors.redAccent),
                      ),
                    ),
                  );


                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
