// Keep your imports
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_dialog.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/searcher.dart';
import '../../../widgets/admin_bottom_nav.dart';
import '../../accounts/notification_screen.dart';
import 'admin_profile_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int unreadNotifications = 0;
  final AuthService _authService = AuthService();
  Map<String, dynamic>? dashboardData;
  bool showBalance = true;
  bool isLoading = true;
  int _selectedIndex = 0;

  final Color themeColor = AppTheme.themeColor;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
    fetchUnreadNotifications();
  }

  Future<void> fetchDashboardData() async {
    final data = await _authService.getAdminDashboard();
    setState(() {
      dashboardData = data;
      isLoading = false;
    });
  }

  Future<void> fetchUnreadNotifications() async {
    final count = await _authService.getUnreadNotificationCount();
    setState(() => unreadNotifications = count);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
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
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: _buildAdminAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : dashboardData == null
          ? const Center(child: Text('Unable to load dashboard data.'))
          : RefreshIndicator(
        onRefresh: fetchDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/adminFinanceAnalysis');
                },
                child: _buildGlassBalanceCard(),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildNeumorphicStatCard(
                      "Income",
                      "£${dashboardData!['income']?.toStringAsFixed(2) ?? '0.00'}",
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNeumorphicStatCard(
                      "Expenses",
                      "£${dashboardData!['expenses']?.toStringAsFixed(2) ?? '0.00'}",
                      Icons.trending_down,
                      Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _buildQuickAccessList(),
            ],
          ),
        ),
      ),
      floatingActionButton: SpeedDial(
        backgroundColor: themeColor,
        activeIcon: Icons.close,
        spacing: 10,
        children: [
          SpeedDialChild(
              child: const Icon(Icons.person_add),
              label: 'Add Member',
              onTap: () => Navigator.pushNamed(context, '/addMember')),
          SpeedDialChild(
              child: const Icon(Icons.volunteer_activism),
              label: 'Add Contribution',
              onTap: () =>
                  Navigator.pushNamed(context, '/addContribution')),
          SpeedDialChild(
              child: const Icon(Icons.payments),
              label: 'Add Disbursement',
              onTap: () =>
                  Navigator.pushNamed(context, '/addDisbursement')),
          SpeedDialChild(
              child: const Icon(Icons.admin_panel_settings_outlined),
              label: 'Add AdminUser',
              onTap: () =>
                  Navigator.pushNamed(context, '/createAdminUser')),
          SpeedDialChild(
            child: const Icon(Icons.upload_file),
            label: 'Import Legacy',
            onTap: () => Navigator.pushNamed(context, '/importLegacy'),
          ),
        ],
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const AdminBottomNavBar(),

    );
  }

  Widget _buildGlassBalanceCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [themeColor, themeColor.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Balance',
              style: montserratTextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  showBalance
                      ? "£${dashboardData!['balance']?.toStringAsFixed(2) ?? '0.00'}"
                      : "£••••",
                  key: ValueKey(showBalance),
                  style: montserratTextStyle(color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: Icon(
                    showBalance
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.white70),
                onPressed: () =>
                    setState(() => showBalance = !showBalance),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAdminAppBar() {
    return AppBar(
      backgroundColor: AppTheme.appBarColor,
      elevation: 0,
      toolbarHeight: 60,
      automaticallyImplyLeading: false,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar on the left
          GestureDetector(
            onTap: _openAdminProfile,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: themeColor.withOpacity(0.2),
              child: const Icon(Icons.person_2_rounded, color: Colors.black87, size: 22),
            ),
          ),
          const SizedBox(width: 12), // Space between avatar and text
          // Greeting and name
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _greeting(),
                style: montserratTextStyle(color: Colors.grey[600],
                  fontSize: 14,),
              ),
              const SizedBox(height: 4),
              Text(
                'Admin',
                style: montserratTextStyle(color: themeColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black87),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ).then((_) => fetchUnreadNotifications());  // Refresh when coming back
              },
            ),
            if (unreadNotifications > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadNotifications.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              )
          ],
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.black87),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await _authService.logout();
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
        ),
      ],
    );
  }


  Widget _buildNeumorphicStatCard(String title, String amount, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFF1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade300, offset: const Offset(4, 4), blurRadius: 10),
          const BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.1),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: montserratTextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount,
                    style: montserratTextStyle(fontSize: 20,
                      fontWeight: FontWeight.bold,),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildQuickAccessList() {
    return Column(
      children: [
        _buildQuickAccess(
            "Members",
            dashboardData!['members'],
            Icons.people,
            '/allMembers'),
        _buildQuickAccess(
            "Contributions",
            dashboardData!['contributions'],
            Icons.volunteer_activism,
            '/contributions'),
        _buildQuickAccess(
            "Welfare Requests",
            dashboardData!['welfare_requests'],
            Icons.request_page,
            '/welfareRequests'),
        _buildQuickAccess(
            "Disbursements",
            dashboardData!['disbursements'],
            Icons.payments,
            '/disbursements'),
        _buildQuickAccess(
            "Pending Records",
            dashboardData!['pending_requests'],
            Icons.hourglass_top,
            '/pendingRecords'),
        _buildQuickAccess(
            "AdminUsers",
            dashboardData!['admin_users'],
            Icons.admin_panel_settings_outlined,
            '/adminUsersList'),
      ],
    );
  }

  Widget _buildQuickAccess(
      String label, dynamic value, IconData icon, String route) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: themeColor),
        title: Text(label,
            style: montserratTextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        subtitle: Text("Total: $value",
            style: montserratTextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing:
        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}
