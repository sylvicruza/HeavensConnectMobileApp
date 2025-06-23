import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../screens/member/memberusers/member_profile_screen.dart';

class MemberBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  const MemberBottomNavBar({super.key, required this.selectedIndex});

  @override
  State<MemberBottomNavBar> createState() => _MemberBottomNavBarState();
}


class _MemberBottomNavBarState extends State<MemberBottomNavBar> {
  int _selectedIndex = 0;
  int unreadNotifications = 0;
  Map<String, dynamic>? memberProfile;

  final AuthService _authService = AuthService();
  final Color themeColor = AppTheme.themeColor;

  @override
  void initState() {
    super.initState();
    fetchProfile();
    fetchUnreadNotifications();
  }

  Future<void> fetchProfile() async {
    final profile = await _authService.getMemberProfile();
    if (mounted) {
      setState(() {
        memberProfile = profile;
      });
    }
  }

  Future<void> fetchUnreadNotifications() async {
    final count = await _authService.getUnreadNotificationCount();
    if (mounted) {
      setState(() {
        unreadNotifications = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Colors.white,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home, 0, '/memberDashboard'),
            _navItem(Icons.attach_money, 1, '/memberContributionList'),
            _navItem(Icons.request_page, 2, '/memberWelfareRequests'),
            _profileNavItem(),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index, String route) {
    return IconButton(
      icon: Stack(
        children: [
          Icon(
            icon,
              color: widget.selectedIndex == index ? themeColor : Colors.grey
          ),
          // Optionally, if you want to add notification badge for specific icons in future
        ],
      ),
      onPressed: () {
        setState(() => _selectedIndex = index);
        Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
      },
    );
  }

  Widget _profileNavItem() {
    return IconButton(
      icon: Icon(
        Icons.person,
        color: _selectedIndex == 3 ? themeColor : Colors.grey,
      ),
      onPressed: () {
        setState(() => _selectedIndex = 3);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MemberProfileScreen(
              memberData: memberProfile ?? {},
            ),
          ),
        );
      },
    );
  }
}
