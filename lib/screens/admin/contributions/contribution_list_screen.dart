import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:heavens_connect/services/contribution_service.dart';
import 'package:heavens_connect/utils/setting_keys.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/admin_bottom_nav.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
/*import 'package:file_saver/file_saver.dart';*/
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';


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
  List<String> sourceOptions = ['all'];

  String selectedStatus = 'all';
  String selectedPaymentMethod = 'all';
  String selectedSource = 'all';
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
      sourceOptions = ['all', ...(['app', 'imported', 'manual'])];
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
      month: selectedMonth == 0 ? null : selectedMonth, // 👈 this line
      year: selectedYear,
      source: selectedSource == 'all' ? null : selectedSource,
      search: searchQuery.isNotEmpty ? searchQuery : null,
    );
    setState(() {
      contributions = data ?? [];
      isLoading = false;
    });
  }

  Future<void> _exportContributionsToExcel() async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Storage permission is required")),
      );
      return;
    }

    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Contributions';

    // Headers
    final headers = ['Member Name', 'Amount', 'Date', 'Status', 'Payment Method'];
    for (int i = 0; i < headers.length; i++) {
      sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
    }

    // Data
    for (int i = 0; i < contributions.length; i++) {
      final row = contributions[i];
      sheet.getRangeByIndex(i + 2, 1).setText(row['member_name'] ?? '');
      sheet.getRangeByIndex(i + 2, 2).setNumber(double.tryParse(row['amount'].toString()) ?? 0.0);
      sheet.getRangeByIndex(i + 2, 3).setText((row['created_at'] ?? '').toString().split("T")[0]);
      sheet.getRangeByIndex(i + 2, 4).setText(row['status'] ?? '');
      sheet.getRangeByIndex(i + 2, 5).setText(row['payment_method'] ?? '');
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final fileName = "contributions_${selectedYear}_${selectedMonth == 0 ? 'all' : selectedMonth}";

  /*  await FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(bytes),
      ext: "xlsx",
      mimeType: MimeType.microsoftExcel,
    );*/





    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Exported successfully to Downloads folder")),
    );
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
              Text('Filter Contributions', style: montserratTextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildDropdown(statusOptions, selectedStatus, (value) => setState(() => selectedStatus = value), 'Status'),
              const SizedBox(height: 12),
              _buildDropdown(paymentMethodOptions, selectedPaymentMethod, (value) => setState(() => selectedPaymentMethod = value), 'Payment Method'),
              const SizedBox(height: 12),
              _buildDropdown(sourceOptions, selectedSource, (value) => setState(() => selectedSource = value), 'Source'),
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
                    style: montserratTextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,),
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
      backgroundColor: AppTheme.lightBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.appBarColor,
          elevation: 0.5,
          title: Text(
            'Contributions',
            style: montserratTextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: themeColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download_rounded),
              onPressed: _exportContributionsToExcel,
            ),
            IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              onPressed: _showFilterSheet,
            ),
          ],
        )
,
        body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by member name...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
          )
,
          Expanded(
            child: contributions.isEmpty
                ? Center(child: Text('No contributions found', style: montserratTextStyle()))
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
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: themeColor,
        overlayColor: Colors.black,
        overlayOpacity: 0.4,
        spacing: 12,
        spaceBetweenChildren: 8,
        shape: const CircleBorder(),
        children: [
          SpeedDialChild(
            child: const Icon(Icons.edit_document, color: Colors.white),
            label: 'Add Single Contribution',
            backgroundColor: Colors.deepPurple,
            onTap: () async {
              final result = await Navigator.pushNamed(context, '/addContribution');
              if (result == true) fetchContributions();
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.upload_file, color: Colors.white),
            label: 'Upload Contribution',
            backgroundColor: Colors.indigo,
            onTap: () async {
              final result = await Navigator.pushNamed(context, '/importLegacy');
              if (result == true) fetchContributions();
            },
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

  Widget _buildMonthDropdown() {
    return DropdownButtonFormField<int>(
      value: selectedMonth,
      items: [
        DropdownMenuItem(value: 0, child: Text('All')),
        ...List.generate(12, (index) {
          int monthValue = index + 1;
          return DropdownMenuItem(value: monthValue, child: Text(monthName(monthValue)));
        }),
      ],
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
    final source = contribution['source'] ?? 'app';
    final memberName = contribution['member_name'] ?? '';
    final amount = contribution['amount']?.toString() ?? '0.00';
    final createdAt = contribution['created_at'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(memberName, style: montserratTextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('£$amount', style: montserratTextStyle(color: themeColor, fontWeight: FontWeight.w500)),
            Text('Payment: ${capitalize(paymentMethod)}', style: montserratTextStyle(fontSize: 12)),
            Text('Date: ${createdAt.split("T")[0]}', style: montserratTextStyle(fontSize: 12, color: Colors.grey)),
            _buildSourceBadge(source),
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
      child: Text(label, style: montserratTextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  Widget _buildSourceBadge(String source) {
    Color color;
    String label;

    switch (source) {
      case 'app':
        color = Colors.teal;
        label = 'App';
        break;
      case 'imported':
        color = Colors.indigo;
        label = 'Imported';
        break;
      case 'manual':
        color = Colors.blueGrey;
        label = 'Manual';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label, style: montserratTextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
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

