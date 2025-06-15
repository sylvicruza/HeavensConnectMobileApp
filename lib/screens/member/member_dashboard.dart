import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heavens_connect/services/contribution_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_config.dart';
import '../../utils/app_theme.dart';
import '../../widgets/member_bottom_nav.dart';
import '../notification_screen.dart';
import 'member_contribution_details_screen.dart';
import 'member_profile_screen.dart';

class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  int unreadNotifications = 0;
  final AuthService _authService = AuthService();
  final Color themeColor = AppTheme.themeColor;

  bool showBalance = true;
  int _selectedIndex = 0;
  bool isLoading = true;

  Map<String, dynamic>? memberProfile;
  Map<String, dynamic>? dashboardData;
  List<dynamic> contributions = [];

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
    fetchUnreadNotifications();
  }

  Future<void> fetchDashboardData() async {

    final profile = await _authService.getMemberProfile();
    if (profile != null) {
      final dashboard = await _authService.getMemberDashboard(profile['id']);
      final contributionList = await _authService.getContributionsByUsername(profile['username']);
      setState(() {
        memberProfile = profile;
        dashboardData = dashboard;
        contributions = contributionList ?? [];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchUnreadNotifications() async {
    final count = await _authService.getUnreadNotificationCount();
    setState(() => unreadNotifications = count);
  }

  @override
  Widget build(BuildContext context) {
    final String? profilePicture = memberProfile?['profile_picture'];
    final uri =  _authService.baseUrl;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      // In your AppBar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: profilePicture != null
                  ? NetworkImage(
                profilePicture.startsWith('http')
                    ? profilePicture
                    : '$uri$profilePicture',
              )
                  : null,
              backgroundColor: themeColor.withOpacity(0.2),
              child: profilePicture == null
                  ? Text(
                memberProfile?['full_name'] != null
                    ? memberProfile!['full_name'][0].toUpperCase()
                    : '?',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: themeColor),
              )
                  : null,
            ),
            const SizedBox(width: 10),
            /// 🛠 Wrap this Column in Expanded to prevent overflow
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    memberProfile?['full_name'] ?? '',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis, // 👈 optional
                    maxLines: 1, // 👈 optional
                  ),
                ],
              ),
            ),
          ],
        ),

        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.black87),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                ),
              ),
              if (unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadNotifications',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),

          IconButton(
              icon: const Icon(Icons.logout, color: Colors.black),
              onPressed: () async {
                await _authService.logout();
                Navigator.pushReplacementNamed(context, '/login');
              }),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: fetchDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/member-account-statement');
                },
                child:  _buildGlassBalanceCard(),
              ),

              const SizedBox(height: 28),
              _buildNeumorphicQuickActions(),
              const SizedBox(height: 20),
              _buildRecentContributions(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: MemberBottomNavBar(selectedIndex: 0),

    );
  }



  /// GLASSMORPHIC BALANCE CARD
  Widget _buildGlassBalanceCard() {
    double balance = dashboardData?['balance']?.toDouble() ?? 0.0;
    String memberId = memberProfile?['member_id'] ?? '';
    String name = memberProfile?['full_name'] ?? '';
    String regDate = memberProfile?['joined_date']?.split('T')[0] ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [themeColor, themeColor.withOpacity(0.8)]),
          boxShadow: [
            BoxShadow(
                color: themeColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ],
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Stack(
            children: [
              // Bottom right curved effect
              Positioned(
                right: -80,
                bottom: -80,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Name
                    Text(
                      name,
                      style: GoogleFonts.montserrat(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),

                    /// Masked card number + Member ID
                    Text(
                      "Member ID",
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: Colors.white70,
                          letterSpacing: 4),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      memberId,
                      style: GoogleFonts.montserrat(
                          fontSize: 16, color: Colors.white),
                    ),

                    const Spacer(),

                    /// Bottom row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Welfare Balance",
                                style: GoogleFonts.montserrat(
                                    color: Colors.white70, fontSize: 12)),
                            Text(
                              showBalance
                                  ? "£${balance.toStringAsFixed(2)}"
                                  : "£••••",
                              style: GoogleFonts.montserrat(
                                  fontSize: 26,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("Reg. Date",
                                style: GoogleFonts.montserrat(
                                    color: Colors.white70, fontSize: 12)),
                            Text(
                              regDate,
                              style: GoogleFonts.montserrat(
                                  fontSize: 14, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }



  /// QUICK ACTIONS
  Widget _buildNeumorphicQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _neumorphicButton(Icons.attach_money, 'Contribute', () => Navigator.pushNamed(context, '/memberAddContribution')),
            _neumorphicButton(Icons.request_page, 'Request', () => Navigator.pushNamed(context, '/memberSubmitWelfareRequest')),
            _neumorphicButton(Icons.person, 'Profile', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MemberProfileScreen(memberData: memberProfile ?? {}),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _neumorphicButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFF1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade300, offset: const Offset(4, 4), blurRadius: 10),
            const BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 10),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: themeColor, size: 28),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.montserrat(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  /// RECENT CONTRIBUTIONS
  Widget _buildRecentContributions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Contributions', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/memberContributionList'),
              child: Text('See All', style: GoogleFonts.montserrat(color: themeColor, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: contributions.isEmpty
              ? Center(child: Text('No contributions yet.', style: GoogleFonts.montserrat(color: Colors.grey)))
              : ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: contributions.length.clamp(0, 5),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final c = contributions[index];
              final amount = "£${double.parse(c['amount'].toString()).toStringAsFixed(2)}";
              final month = _monthName(c['month']);
              final year = c['year'];
              final status = c['status'];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MemberContributionDetailScreen(contribution: c),
                    ),
                  );
                },
                child: _contributionCard("$month $year", amount, status),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _contributionCard(String date, String amount, String status) {
    Color badgeColor;
    switch (status.toLowerCase()) {
      case 'verified':
        badgeColor = Colors.green;
        break;
      case 'pending':
        badgeColor = Colors.orange;
        break;
      case 'rejected':
        badgeColor = Colors.red;
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(amount, style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: themeColor)),
          const SizedBox(height: 6),
          Text(date, style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(status, style: GoogleFonts.montserrat(color: badgeColor, fontWeight: FontWeight.w600, fontSize: 12)),
          )
        ],
      ),
    );
  }

  /// BOTTOM NAVIGATION


  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
