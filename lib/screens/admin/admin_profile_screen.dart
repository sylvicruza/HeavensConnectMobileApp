import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../utils/app_dialog.dart';
import '../../utils/app_theme.dart';
import '../change_password_screen.dart';
import 'admin_display_settings.dart';
import 'edit_admin_profile_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  final Map<String, dynamic> adminData;

  const AdminProfileScreen({super.key, required this.adminData});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  final Color themeColor = AppTheme.themeColor;
  bool _darkMode = false;
  bool _notifications = true;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: themeColor),
        title: Text('Profile and settings',
            style: GoogleFonts.montserrat(
                color: Colors.black, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: themeColor),
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade50]),
            ),
            child: Row(
              children: [
                _tabButton(0, 'Profile'),
                _tabButton(1, 'Settings'),
              ],
            ),
          ),
          Expanded(
            child:
            _selectedIndex == 0 ? _buildProfileTab() : _buildSettingsTab(),
          )
        ],
      ),
    );
  }

  Widget _tabButton(int index, String title) {
    bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? themeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.montserrat(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    final data = widget.adminData;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: ListView(
        children: [
          const SizedBox(height: 10),
          _profileCard('Name', data['full_name']),
          _profileCard('Admin ID', data['id'].toString()),
          _profileCard('Role', data['role'].toUpperCase()),
          _profileCard('Mobile', data['phone_number']),
          _profileCard('Email', data['email'] ?? 'N/A'),
          _profileCard('Last Login', data['last_login_at'] ?? 'N/A'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditAdminProfileScreen(adminData: widget.adminData),
                ),
              );

              // If updated, reload the profile
              if (updated == true) {
                final refreshedData = await _authService.getAdminProfile();
                if (refreshedData != null) {
                  setState(() {
                    widget.adminData.clear();
                    widget.adminData.addAll(refreshedData);
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text('Edit Profile', style: GoogleFonts.montserrat(
                color: Colors.white, fontWeight: FontWeight.w600)),
          ),

        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        children: [
          const SizedBox(height: 10),
          _settingsSection('App Setup', [
            _settingsItem(Icons.display_settings, 'Display Settings', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
              );
            }),
            _settingsItem(Icons.lock_reset, 'Reset your password', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            }),
            _settingsItem(Icons.timer, 'Auto logoff', () {
              _logout();
            })

          ]),
          const SizedBox(height: 20),
          _settingsSection('Preferences', [
            _toggleItem(Icons.dark_mode, 'Dark Mode', _darkMode, (value) {
              setState(() => _darkMode = value);
              // Save to SharedPreferences or apply theme change in the app
            }),
            _toggleItem(Icons.notifications_active, 'Notifications', _notifications, (value) {
              setState(() => _notifications = value);
            }),
          ]),
        ],
      ),
    );
  }


  Widget _profileCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.montserrat(
                  color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _settingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 10),
        ...items,
      ],
    );
  }

  Widget _settingsItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        leading: Icon(icon, color: themeColor),
        title: Text(title,
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w500, color: Colors.black87)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _toggleItem(IconData icon, String title, bool currentValue, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        secondary: Icon(icon, color: themeColor),
        title: Text(title,
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w500, color: Colors.black87)),
        value: currentValue,
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _resetApp() async {
    await _authService.logout();  // Clears storage already in your logout method.
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

}
