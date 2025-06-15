import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heavens_connect/services/auth_service.dart';
import 'package:heavens_connect/services/contribution_service.dart';
import 'package:heavens_connect/utils/setting_keys.dart';
import 'package:heavens_connect/widgets/member_bottom_nav.dart';

import '../../utils/app_theme.dart';
import 'member_contribution_details_screen.dart';

class MemberContributionListScreen extends StatefulWidget {
  const MemberContributionListScreen({super.key});

  @override
  State<MemberContributionListScreen> createState() => _MemberContributionListScreenState();
}

class _MemberContributionListScreenState extends State<MemberContributionListScreen> {
  final AuthService _authService = AuthService();
  final Color themeColor = AppTheme.themeColor;

  List<dynamic> contributions = [];
  List<String> statusOptions = ['all'];
  List<String> paymentMethods = ['all'];

  String selectedStatus = 'all';
  String selectedPaymentMethod = 'all';
  int? selectedMonth;
  int? selectedYear;

  bool isLoading = true;
  bool settingsLoaded = false;

  @override
  void initState() {
    super.initState();
    loadSettingsAndFetchContributions();
  }

  Future<void> loadSettingsAndFetchContributions() async {
    final settings = await _authService.getSystemSettings();

    setState(() {
      statusOptions = ['all', ...(settings[SettingKeys.contributionStatuses] ?? ['pending', 'verified', 'rejected'])];
      paymentMethods = ['all', ...(settings[SettingKeys.paymentMethods] ?? ['cash', 'transfer'])];
      settingsLoaded = true;
    });

    fetchContributions();
  }

  Future<void> fetchContributions() async {
    setState(() => isLoading = true);
    final profile = await _authService.getMemberProfile();
    if (profile != null) {
      final data = await _authService.getContributionsByUsername(
        profile['username'],
        status: selectedStatus == 'all' ? null : selectedStatus,
        paymentMethod: selectedPaymentMethod == 'all' ? null : selectedPaymentMethod,
        month: selectedMonth,
        year: selectedYear,
      );
      setState(() {
        contributions = data ?? [];
        isLoading = false;
      });
    }
  }

  void _showFilterSheet() {
    String tempStatus = selectedStatus;
    String tempPaymentMethod = selectedPaymentMethod;
    int? tempMonth = selectedMonth;
    int? tempYear = selectedYear;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return settingsLoaded
            ? Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              Text('Filter Contributions', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildDropdown(statusOptions, tempStatus, (value) => tempStatus = value!, 'Status'),
              const SizedBox(height: 12),
              _buildDropdown(paymentMethods, tempPaymentMethod, (value) => tempPaymentMethod = value!, 'Payment Method'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildMonthDropdown(tempMonth, (value) => tempMonth = value)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildYearDropdown(tempYear, (value) => tempYear = value)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedStatus = tempStatus;
                      selectedPaymentMethod = tempPaymentMethod;
                      selectedMonth = tempMonth;
                      selectedYear = tempYear;
                    });
                    Navigator.pop(context);
                    fetchContributions();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Apply Filters', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        )
            : const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: themeColor),
        title: Text('My Contributions', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: themeColor, fontSize: 18)),
        actions: [
          TextButton.icon(
            onPressed: _showFilterSheet,
            icon: const Icon(Icons.filter_list),
            label: Text('Filter', style: GoogleFonts.montserrat(color: themeColor)),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : contributions.isEmpty
          ? Center(child: Text('No contributions found', style: GoogleFonts.montserrat()))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: contributions.length,
        itemBuilder: (context, index) {
          final c = contributions[index];
          return _buildContributionCard(c);
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: themeColor,
        child: const Icon(Icons.add, color: Colors.white,),
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/memberAddContribution');
          if (result == true) fetchContributions();
        },
      ),
      bottomNavigationBar: MemberBottomNavBar(selectedIndex: 1),
    );
  }

  Widget _buildDropdown(List<String> options, String selected, ValueChanged<String?> onChanged, String label) {
    return DropdownButtonFormField<String>(
      value: selected,
      items: options.map((e) => DropdownMenuItem(value: e, child: Text(capitalize(e)))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildMonthDropdown(int? selected, ValueChanged<int?> onChanged) {
    return DropdownButtonFormField<int>(
      value: selected,
      items: [null, ...List.generate(12, (index) => index + 1)].map((month) {
        return DropdownMenuItem(
          value: month,
          child: Text(month == null ? 'All Months' : monthName(month)),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Month',
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildYearDropdown(int? selected, ValueChanged<int?> onChanged) {
    int currentYear = DateTime.now().year;
    return DropdownButtonFormField<int>(
      value: selected,
      items: [null, ...List.generate(5, (index) => currentYear - index)].map((year) {
        return DropdownMenuItem(
          value: year,
          child: Text(year == null ? 'All Years' : year.toString()),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Year',
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildContributionCard(dynamic c) {
    final amount = c['amount']?.toString() ?? '0.00';
    final month = monthName(c['month']);
    final year = c['year'];
    final status = c['status'];
    final paymentMethod = c['payment_method'];

    Color statusColor;
    switch (status) {
      case 'verified':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: ListTile(
        title: Text('£$amount - $month $year', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        subtitle: Text('Payment: ${capitalize(paymentMethod)}', style: GoogleFonts.montserrat()),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(capitalize(status), style: GoogleFonts.montserrat(color: statusColor, fontWeight: FontWeight.w600)),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MemberContributionDetailScreen(contribution: c),
            ),
          );
        },
      ),
    );
  }
}

String capitalize(String text) => text.isNotEmpty ? '${text[0].toUpperCase()}${text.substring(1)}' : '';

String monthName(int month) {
  const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  return months[month - 1];
}
