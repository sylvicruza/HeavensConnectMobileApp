import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heavens_connect/services/auth_service.dart';
import '../../../utils/app_dialog.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/admin_bottom_nav.dart';

class AdminUsersListScreen extends StatefulWidget {
  const AdminUsersListScreen({super.key});

  @override
  State<AdminUsersListScreen> createState() => _AdminUsersListScreenState();
}

class _AdminUsersListScreenState extends State<AdminUsersListScreen> {
  final AuthService _authService = AuthService();
  List<dynamic> admins = [];
  bool isLoading = true;

  final Color themeColor = AppTheme.themeColor;

  @override
  void initState() {
    super.initState();
    fetchAdminUsers();
  }

  Future<void> fetchAdminUsers() async {
    setState(() => isLoading = true);
    final data = await _authService.getAdminUsers();
    setState(() {
      admins = data ?? [];
      isLoading = false;
    });
  }

  Widget _buildAdminCard(dynamic admin) {
    final String initials = _getInitials(admin['full_name']);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: themeColor.withOpacity(0.15),
          child: Text(initials, style: montserratTextStyle(color: themeColor, fontWeight: FontWeight.bold)),
        ),
        title: Text(admin['full_name'], style: montserratTextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Email: ${admin['email'] ?? 'Not provided'}',
                style: montserratTextStyle(fontSize: 12, color: Colors.grey[700])),
            Text('Phone: ${admin['phone_number']}',
                style: montserratTextStyle(fontSize: 12, color: Colors.grey[700])),
            Text('Role: ${admin['role'].toUpperCase()}',
                style: montserratTextStyle(fontSize: 12, color: themeColor)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.pushNamed(
                context,
                '/editAdminUser',
                arguments: admin,
              ).then((updated) {
                if (updated == true) fetchAdminUsers();
              });
            } else if (value == 'delete') {
              _confirmDelete(admin['id']);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int adminId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Admin'),
        content: const Text('Are you sure you want to delete this Admin User?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              AppDialog.showLoadingDialog(context);
              final success = await _authService.deleteAdminUser(adminId);
              Navigator.pop(context);

              if (success) {
                AppDialog.showSuccessDialog(
                    context, title: 'Deleted', message: 'Admin User deleted successfully.');
                fetchAdminUsers();
              } else {
                AppDialog.showWarningDialog(
                    context, title: 'Failed', message: 'Could not delete Admin User.');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return parts[0][0].toUpperCase() + parts[1][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Users', style: montserratTextStyle(color: themeColor)),
        backgroundColor: AppTheme.appBarColor,
        elevation: 1,
        iconTheme: IconThemeData(color: themeColor),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : admins.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings_outlined,
                size: 60, color: themeColor.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text('No Admin Users Found',
                style: montserratTextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('Tap the + button to add an admin user.',
                style: montserratTextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: admins.length,
        itemBuilder: (context, index) => _buildAdminCard(admins[index]),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: themeColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.pushNamed(context, '/createAdminUser').then((value) {
            if (value == true) fetchAdminUsers();
          });
        },
      ),
      bottomNavigationBar: const AdminBottomNavBar(),
    );
  }
}
