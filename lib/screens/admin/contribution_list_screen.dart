import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heavens_connect/services/contribution_service.dart';
import 'package:heavens_connect/utils/setting_keys.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/admin_bottom_nav.dart';

class ContributionListScreen extends StatefulWidget {
  const ContributionListScreen({super.key});

  @override
  State<ContributionListScreen> createState() => _ContributionListScreenState();
}

class _ContributionListScreenState extends State<ContributionListScreen> {
  final AuthService _authService = AuthService();
  List<dynamic> contributions = [];
  bool isLoading = true;
  bool settingsLoading = true;

  List<String> statusOptions = ['all'];
  List<String> paymentMethodOptions = ['all'];

  String selectedStatus = 'all';
  String selectedPaymentMethod = 'all';
  late int selectedMonth;
  late int selectedYear;
  String searchQuery = '';

  bool _initialized = false;
  Timer? _debounce;
  final Color themeColor = AppTheme.themeColor;

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime.now().month;
    selectedYear = DateTime.now().year;
    _loadSystemSettings();
  }

  Future<void> _loadSystemSettings() async {
    final settings = await _authService.getSystemSettings();
    setState(() {
      statusOptions = ['all', ...(settings[SettingKeys.contributionStatuses] ?? ['pending', 'verified', 'rejected'])];
      paymentMethodOptions = ['all', ...(settings[SettingKeys.paymentMethods] ?? ['cash', 'transfer'])];
      settingsLoading = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['status'] != null) {
        selectedStatus = args['status'];
      }
      fetchContributions();
      _initialized = true;
    }
  }

  Future<void> fetchContributions() async {
    setState(() => isLoading = true);
    final data = await _authService.getContributions(
      status: selectedStatus == 'all' ? null : selectedStatus,
      paymentMethod: selectedPaymentMethod == 'all' ? null : selectedPaymentMethod,
      month: selectedMonth,
      year: selectedYear,
      search: searchQuery.isNotEmpty ? searchQuery : null,
    );
    setState(() {
      contributions = data ?? [];
      isLoading = false;
    });
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => searchQuery = value);
      fetchContributions();
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: settingsLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text('Filter Contributions', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildDropdown(statusOptions, selectedStatus, (value) => setState(() => selectedStatus = value), 'Status'),
              const SizedBox(height: 12),
              _buildDropdown(paymentMethodOptions, selectedPaymentMethod, (value) => setState(() => selectedPaymentMethod = value), 'Payment Method'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildMonthDropdown()),
                  const SizedBox(width: 8),
                  Expanded(child: _buildYearDropdown()),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    fetchContributions();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: themeColor),
        title: Text('Contributions', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: themeColor)),
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
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by member name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: contributions.isEmpty
                ? Center(child: Text('No contributions found', style: GoogleFonts.montserrat()))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: contributions.length,
              itemBuilder: (context, index) {
                final contribution = contributions[index];
                return _buildContributionCard(contribution);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: themeColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/addContribution');
          if (result == true) fetchContributions();
        },
      ),
      bottomNavigationBar: const AdminBottomNavBar(),
    );
  }

  Widget _buildDropdown(List<String> options, String selected, ValueChanged<String> onChanged, String label) {
    return DropdownButtonFormField<String>(
      value: selected,
      items: options.map((e) => DropdownMenuItem(value: e, child: Text(capitalize(e)))).toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildMonthDropdown() {
    return DropdownButtonFormField<int>(
      value: selectedMonth,
      items: List.generate(12, (index) {
        int monthValue = index + 1;
        return DropdownMenuItem(value: monthValue, child: Text(monthName(monthValue)));
      }),
      onChanged: (value) {
        if (value != null) setState(() => selectedMonth = value);
      },
      decoration: InputDecoration(
        labelText: 'Month',
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildYearDropdown() {
    int currentYear = DateTime.now().year;
    return DropdownButtonFormField<int>(
      value: selectedYear,
      items: List.generate(5, (index) {
        int yearValue = currentYear - index;
        return DropdownMenuItem(value: yearValue, child: Text(yearValue.toString()));
      }),
      onChanged: (value) {
        if (value != null) setState(() => selectedYear = value);
      },
      decoration: InputDecoration(
        labelText: 'Year',
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildContributionCard(dynamic contribution) {
    final status = contribution['status'] ?? 'pending';
    final paymentMethod = contribution['payment_method'] ?? '';
    final memberName = contribution['member_name'] ?? '';
    final amount = contribution['amount']?.toString() ?? '0.00';
    final createdAt = contribution['created_at'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(memberName, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('£$amount', style: GoogleFonts.montserrat(color: themeColor, fontWeight: FontWeight.w500)),
            Text('Payment: ${capitalize(paymentMethod)}', style: GoogleFonts.montserrat(fontSize: 12)),
            Text('Date: ${createdAt.split("T")[0]}', style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: _buildStatusBadge(status),
        onTap: () => Navigator.pushNamed(context, '/contributionDetail', arguments: contribution['id']),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label = capitalize(status);

    switch (status) {
      case 'verified':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.montserrat(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }


}

String capitalize(String text) => text.isNotEmpty ? '${text[0].toUpperCase()}${text.substring(1)}' : '';

String monthName(int month) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return months[month - 1];
}
