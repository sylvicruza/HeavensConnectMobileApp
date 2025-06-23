import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/admin/adminusers/admin_profile_screen.dart';
import '../services/auth_service.dart';
import '../utils/app_dialog.dart';
import '../utils/app_theme.dart';
import '../utils/searcher.dart';

class AdminBottomNavBar extends StatefulWidget {
  const AdminBottomNavBar({super.key});

  @override
  State<AdminBottomNavBar> createState() => _AdminBottomNavBarState();
}

class _AdminBottomNavBarState extends State<AdminBottomNavBar> {
  final Color themeColor = AppTheme.themeColor;
  final AuthService _authService = AuthService();

  int selectedIndex = 0;
  int pendingRequests = 0;

  @override
  void initState() {
    super.initState();
    fetchPendingRequests();
  }

  Future<void> fetchPendingRequests() async {
    final data = await _authService.getAdminDashboard();
    if (mounted) {
      setState(() {
        pendingRequests = data?['pending_requests'] ?? 0;
      });
    }
  }

  void _handleTap(int index) {
    setState(() => selectedIndex = index);
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(
          context, '/adminDashboard', (route) => false);
    } else if (index == 1) {
      showSearch(
        context: context,
        delegate: AdminSearchDelegate(authService: _authService),
      );
    } else if (index == 2) {
      Navigator.pushNamed(context, '/pendingRecords');
    } else if (index == 3) {
      _openAdminProfile();
    }
  }

  void _openAdminProfile() async {
    final profile = await _authService.getAdminProfile();
    if (profile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminProfileScreen(adminData: profile),
        ),
      );
    } else {
      AppDialog.showWarningDialog(
          context,
          title: 'Error',
          message: 'Unable to fetch profile. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      color: Colors.white,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.home,
                  color: selectedIndex == 0 ? themeColor : Colors.grey),
              onPressed: () => _handleTap(0),
            ),
            IconButton(
              icon: Icon(Icons.search,
                  color: selectedIndex == 1 ? themeColor : Colors.grey),
              onPressed: () => _handleTap(1),
            ),
            const SizedBox(width: 40),
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.pending_actions,
                      color: selectedIndex == 2 ? themeColor : Colors.grey),
                  onPressed: () => _handleTap(2),
                ),
                if (pendingRequests > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$pendingRequests',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.settings,
                  color: selectedIndex == 3 ? themeColor : Colors.grey),
              onPressed: () => _handleTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

