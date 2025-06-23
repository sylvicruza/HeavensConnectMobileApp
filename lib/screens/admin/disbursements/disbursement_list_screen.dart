import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heavens_connect/services/auth_service.dart';
import 'package:heavens_connect/utils/setting_keys.dart';

import '../../../utils/app_theme.dart';
import '../../../widgets/admin_bottom_nav.dart';

class AdminDisbursementListScreen extends StatefulWidget {
  const AdminDisbursementListScreen({super.key});

  @override
  State<AdminDisbursementListScreen> createState() => _AdminDisbursementListScreenState();
}

class _AdminDisbursementListScreenState extends State<AdminDisbursementListScreen> {
  final AuthService _authService = AuthService();
  final Color themeColor = AppTheme.themeColor;

  List<dynamic> disbursements = [];
  List<String> paymentMethods = ['all'];
  List<String> categories = ['all'];

  String selectedPaymentMethod = 'all';
  String selectedCategory = 'all';
  String searchQuery = '';
  Timer? _debounce;

  bool isLoading = true;
  bool settingsLoading = true;

  @override
  void initState() {
    super.initState();
    loadSettingsAndFetchDisbursements();
  }

  Future<void> loadSettingsAndFetchDisbursements() async {
    final settings = await _authService.getSystemSettings();

    setState(() {
      paymentMethods = ['all', ...(settings[SettingKeys.paymentMethods] ?? ['cash', 'transfer'])];
      categories = ['all', ...(settings[SettingKeys.categories] ?? ['school_fees', 'marriage', 'funeral', 'others'])];
      settingsLoading = false;
    });

    fetchDisbursements();
  }

  Future<void> fetchDisbursements() async {
    setState(() => isLoading = true);
    final data = await _authService.getDisbursements(
      paymentMethod: selectedPaymentMethod == 'all' ? null : selectedPaymentMethod,
      category: selectedCategory == 'all' ? null : selectedCategory,
      search: searchQuery.isNotEmpty ? searchQuery : null,
    );
    setState(() {
      disbursements = data ?? [];
      isLoading = false;
    });
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => searchQuery = value);
      fetchDisbursements();
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: settingsLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Text('Filter Disbursements', style: montserratTextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDropdown(paymentMethods, selectedPaymentMethod, (val) => setState(() => selectedPaymentMethod = val), 'Payment Method'),
            const SizedBox(height: 12),
            _buildDropdown(categories, selectedCategory, (val) => setState(() => selectedCategory = val), 'Category'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                fetchDisbursements();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),

              child: Text('Apply Filters', style: montserratTextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(List<String> options, String selected, ValueChanged<String> onChanged, String label) {
    return DropdownButtonFormField<String>(
      value: selected,
      items: options.map((e) => DropdownMenuItem(value: e, child: Text(capitalize(e.replaceAll('_', ' '))))).toList(),
      onChanged: (val) => val != null ? onChanged(val) : null,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDisbursementCard(dynamic disb) {
    final recipient = disb['member_name'] ?? 'Unregistered';
    final amount = "£${disb['amount'].toString()}";
    final category = capitalize(disb['category'] ?? '');
    final method = disb['payment_method'] ?? '';
    final date = disb['disbursed_at']?.split('T')[0] ?? '';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(recipient, style: montserratTextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category, style: montserratTextStyle(color: themeColor)),
            Text('$amount via ${capitalize(method)}'),
            Text('Date: $date', style: montserratTextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        onTap: () => Navigator.pushNamed(context, '/adminDisbursementDetail', arguments: disb),
      ),
    );
  }

  String capitalize(String text) => text.isNotEmpty ? '${text[0].toUpperCase()}${text.substring(1)}' : '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor,
        elevation: 1,
        iconTheme: IconThemeData(color: themeColor),
        title: Text('Disbursements', style: montserratTextStyle(color: themeColor, fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: _showFilterSheet,
            icon: const Icon(Icons.filter_list),
            label: Text('Filter', style: montserratTextStyle(color: themeColor)),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : disbursements.isEmpty
          ? Center(child: Text('No disbursements found', style: montserratTextStyle()))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: disbursements.length,
        itemBuilder: (context, index) => _buildDisbursementCard(disbursements[index]),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: themeColor,
        onPressed: () {
          Navigator.pushNamed(context, '/addDisbursement').then((value) {
            if (value == true) fetchDisbursements();
          });
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const AdminBottomNavBar(),
    );
  }
}
