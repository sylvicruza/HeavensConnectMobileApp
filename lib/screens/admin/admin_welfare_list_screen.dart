import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heavens_connect/utils/setting_keys.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/admin_bottom_nav.dart';

class AdminWelfareRequestListScreen extends StatefulWidget {
  const AdminWelfareRequestListScreen({super.key});

  @override
  State<AdminWelfareRequestListScreen> createState() => _AdminWelfareRequestListScreenState();
}

class _AdminWelfareRequestListScreenState extends State<AdminWelfareRequestListScreen> {
  final AuthService _authService = AuthService();
  final Color themeColor = AppTheme.themeColor;

  List<dynamic> welfareRequests = [];
  bool isLoading = true;
  bool settingsLoading = true;

  Map<String, List<String>> systemSettings = {};
  List<String> statusOptions = [];
  List<String> categoryOptions = [];

  String selectedStatus = 'all';
  String selectedCategory = 'all';
  String searchQuery = '';

  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('status')) {
        selectedStatus = args['status'] ?? 'all';
      }
      _loadSystemSettings();
    });
  }

  Future<void> _loadSystemSettings() async {
    final settings = await _authService.getSystemSettings();

    final statuses = settings[SettingKeys.welfareStatuses] ?? ['pending', 'approved', 'declined', 'paid'];
    final categories = settings[SettingKeys.categories] ?? [
      'school_fees', 'marriage', 'funeral', 'job_loss', 'medical',
      'baby_dedication', 'food', 'rent', 'others'
    ];

    setState(() {
      systemSettings = settings;
      statusOptions = ['all', ...statuses];
      categoryOptions = ['all', ...categories];
      settingsLoading = false;
    });

    fetchRequests();
  }

  Future<void> fetchRequests() async {
    setState(() => isLoading = true);
    final data = await _authService.getWelfareRequests(
      status: selectedStatus == 'all' ? null : selectedStatus,
      category: selectedCategory == 'all' ? null : selectedCategory,
      search: searchQuery.isNotEmpty ? searchQuery : null,
    );
    setState(() {
      welfareRequests = data ?? [];
      isLoading = false;
    });
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => searchQuery = value);
      fetchRequests();
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              Text('Filter Welfare Requests', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildDropdown(statusOptions, selectedStatus, (value) => setState(() => selectedStatus = value), 'Status'),
              const SizedBox(height: 12),
              _buildDropdown(categoryOptions, selectedCategory, (value) => setState(() => selectedCategory = value), 'Category'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    fetchRequests();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Apply Filters', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
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
        title: Text('Welfare Requests', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: themeColor)),
        actions: [
          TextButton.icon(
            onPressed: settingsLoading ? null : _showFilterSheet,
            icon: const Icon(Icons.filter_list),
            label: Text('Filter', style: GoogleFonts.montserrat(color: themeColor)),
          ),
        ],
      ),
      body: isLoading || settingsLoading
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
            child: welfareRequests.isEmpty
                ? Center(child: Text('No welfare requests found', style: GoogleFonts.montserrat()))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: welfareRequests.length,
              itemBuilder: (context, index) {
                final request = welfareRequests[index];
                return _buildRequestCard(request);
              },
            ),
          ),
        ],
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

  Widget _buildRequestCard(dynamic request) {
    final memberName = request['member_name'] ?? 'Unknown';
    final category = capitalize(request['category'] ?? 'Unknown');
    final status = request['status'] ?? 'pending';
    final amount = request['amount_requested'] != null
        ? "£${double.tryParse(request['amount_requested'].toString())?.toStringAsFixed(2)}"
        : "No amount";
    final requestedAt = request['requested_at']?.split('T')[0] ?? '';

    Color statusColor;
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'declined':
        statusColor = Colors.red;
        break;
      case 'paid':
        statusColor = themeColor;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: ListTile(
        title: Text(memberName, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(category, style: GoogleFonts.montserrat(color: themeColor, fontWeight: FontWeight.w500)),
            Text(amount, style: GoogleFonts.montserrat()),
            Text('Requested: $requestedAt', style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(capitalize(status), style: GoogleFonts.montserrat(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
        onTap: () async {
          final result = await Navigator.pushNamed(context, '/adminWelfareRequestDetail', arguments: request);
          if (result == true) fetchRequests();
        },
      ),
    );
  }

  String capitalize(String text) => text.isNotEmpty ? '${text[0].toUpperCase()}${text.substring(1)}' : '';
}
