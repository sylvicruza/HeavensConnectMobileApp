import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/admin_bottom_nav.dart';

class ViewMemberScreen extends StatefulWidget {
  final Map<String, dynamic> member;

  const ViewMemberScreen({super.key, required this.member});

  @override
  State<ViewMemberScreen> createState() => _ViewMemberScreenState();
}

class _ViewMemberScreenState extends State<ViewMemberScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;
  final Color themeColor = Colors.deepPurple;

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    final data = await _authService.getMemberDashboard(widget.member['id']);
    setState(() {
      dashboardData = data;
      isLoading = false;
    });
  }

  // FORMAT BIG NUMBERS INTO K/M/B
  String formatAmount(num amount) {
    if (amount >= 1000000000) {
      return '£${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '£${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '£${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '£${amount.toStringAsFixed(2)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Member Details',
            style: montserratTextStyle(fontWeight: FontWeight.bold, color: themeColor)),
        backgroundColor: AppTheme.appBarColor,
        elevation: 1,
        iconTheme: IconThemeData(color: themeColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, '/editMember',
                  arguments: widget.member);
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage:
              widget.member['profile_picture'] != null &&
                  widget.member['profile_picture'].isNotEmpty
                  ? NetworkImage(widget.member['profile_picture'])
                  : null,
              backgroundColor: Colors.purple.shade50,
              child: widget.member['profile_picture'] == null ||
                  widget.member['profile_picture'].isEmpty
                  ? Text(
                widget.member['full_name'][0].toUpperCase(),
                style: TextStyle(
                    color: themeColor,
                    fontSize: 30,
                    fontWeight: FontWeight.bold),
              )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(widget.member['full_name'],
                style: montserratTextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Member ID: ${widget.member['member_id']}',
                style: montserratTextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                    child: _buildStatCard(
                        'Balance',
                        formatAmount(dashboardData!['balance']),
                        themeColor)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildStatCard(
                        'Requests',
                        '${dashboardData!['requests_count']}',
                        themeColor)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildStatCard(
                        'Total Spent',
                        formatAmount(
                            dashboardData!['total_spent']),
                        themeColor)),
              ],
            ),
            const SizedBox(height: 20),
            _ExpandableSection(
                Icons.person,
                'Personal Information',
                themeColor,
                _buildPersonalInfo()),
            _ExpandableSection(
                Icons.pie_chart,
                'Contribution vs Spent',
                themeColor,
                _buildPieChartWithBreakdown()),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.lock_reset, color: themeColor),
                title: Text('Reset Password',
                    style: montserratTextStyle(fontWeight: FontWeight.w500)),
                trailing:
                const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushNamed(context, '/forgotPassword',
                      arguments: widget.member);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNavBar(),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: montserratTextStyle(color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(label,
                  style: montserratTextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Username', widget.member['username'] ?? 'N/A'),
        _buildInfoRow('Full Name', widget.member['full_name']),
        _buildInfoRow('Email', widget.member['email'] ?? 'N/A'),
        _buildInfoRow('Phone Number', widget.member['phone_number']),
        _buildInfoRow('Member ID', widget.member['member_id']),
        _buildInfoRow('Status', widget.member['status']),
        _buildInfoRow('Joined Date', widget.member['joined_date']),
        _buildInfoRow('Address', widget.member['address'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: montserratTextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: montserratTextStyle(color: Colors.grey.shade700),
              maxLines: label == 'Address' ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartWithBreakdown() {
    final balance = dashboardData!['balance'] as num;
    final spent = dashboardData!['total_spent'] as num;
    final List<Map<String, dynamic>> contributions =
    List<Map<String, dynamic>>.from(dashboardData!['contributions']);

    final total = balance + spent;
    final contributionPercent = total > 0 ? (balance / total) * 100 : 0;
    final spentPercent = total > 0 ? (spent / total) * 100 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1.3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 50,
              sections: [
                PieChartSectionData(
                  color: Colors.green,
                  value: balance.toDouble(),
                  title: '${contributionPercent.toStringAsFixed(1)}%',
                  radius: 60,
                  titleStyle: montserratTextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                PieChartSectionData(
                  color: Colors.red,
                  value: spent.toDouble(),
                  title: '${spentPercent.toStringAsFixed(1)}%',
                  radius: 60,
                  titleStyle: montserratTextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(themeColor, 'Contributions'),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.redAccent, 'Total Spent'),
          ],
        ),
        const SizedBox(height: 20),
        Text('Monthly Contribution Breakdown:',
            style: montserratTextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...contributions.map((c) {
          final month = c['month'] as int;
          final amount = (c['total'] as num).toStringAsFixed(2);
          final year = c['year'] as int;
          const monthNames = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec'
          ];
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('${monthNames[month - 1]} $year',
                style: montserratTextStyle(fontWeight: FontWeight.w500)),
            trailing: Text('£$amount',
                style: montserratTextStyle(fontWeight: FontWeight.bold, color: themeColor)),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration:
            BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: montserratTextStyle(fontSize: 12)),
      ],
    );
  }
}

class _ExpandableSection extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Widget content;

  const _ExpandableSection(
      this.icon, this.label, this.color, this.content);

  @override
  __ExpandableSectionState createState() => __ExpandableSectionState();
}

class __ExpandableSectionState extends State<_ExpandableSection> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(widget.icon, color: widget.color),
            title: Text(widget.label,
                style:
                montserratTextStyle(fontWeight: FontWeight.w500)),
            trailing: Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 20),
            onTap: () => setState(() => isExpanded = !isExpanded),
          ),
          if (isExpanded)
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: widget.content,
            ),
        ],
      ),
    );
  }
}
