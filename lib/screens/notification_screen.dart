import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../utils/app_theme.dart';

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
    setState(() {
      isLoading = true;  // Always reset loading state
    });

    final data = await _authService.getNotifications();
    await Future.delayed(const Duration(milliseconds: 300));  // 👌 smoother transition
    setState(() {
      notifications = data ?? [];  // Defensive: fallback to empty list
      isLoading = false;
    });

    // Mark all read (no need to wait for this before showing UI)
    if (notifications.isNotEmpty) {
      _authService.markNotificationsAsRead();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = AppTheme.themeColor;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: themeColor),
        title: Text('Notifications',
            style: GoogleFonts.montserrat(
                color: themeColor, fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? Center(
        child: Text(
          'No notifications',
          style: GoogleFonts.montserrat(color: Colors.grey),
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchNotifications,
        child: ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notif = notifications[index] ?? {};
            final title = notif['title'] ?? 'No Title';
            final message = notif['message'] ?? 'No message available';
            final isRead = notif['read'] ?? false;

            return Card(
              margin:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: Icon(Icons.notifications,
                    color: themeColor.withOpacity(0.7)),
                title: Text(title,
                    style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold)),
                subtitle: Text(message),
                trailing: isRead
                    ? null
                    : Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
