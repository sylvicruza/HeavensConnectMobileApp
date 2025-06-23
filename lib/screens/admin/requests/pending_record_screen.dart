import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/admin_bottom_nav.dart';

class PendingRecordsScreen extends StatefulWidget {
  const PendingRecordsScreen({super.key});

  @override
  State<PendingRecordsScreen> createState() => _PendingRecordsScreenState();
}

class _PendingRecordsScreenState extends State<PendingRecordsScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? records;
  bool isLoading = true;
  final Color themeColor = AppTheme.themeColor;

  @override
  void initState() {
    super.initState();
    fetchRecords();
  }

  Future<void> fetchRecords() async {
    final data = await _authService.getPendingRecords();
    setState(() {
      records = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pending Records', style: montserratTextStyle(color: themeColor, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.appBarColor,
        iconTheme: IconThemeData(color: themeColor),
        elevation: 1,
      ),
      backgroundColor: AppTheme.lightBackground,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : records == null
          ? const Center(child: Text("Unable to fetch pending records."))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection("Pending Membership Requests", records!['pending_members'], () => Navigator.pushNamed(context, '/pendingRequests')),
          _buildSection("Pending Contributions", records!['pending_contributions'], () => Navigator.pushNamed(context, '/contributions', arguments: {'status': 'pending'})),
          _buildSection("Pending Welfare Requests", records!['pending_welfare_requests'], () => Navigator.pushNamed(context, '/welfareRequests', arguments: {'status': 'pending'})),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavBar(),
    );
  }

  Widget _buildSection(String title, List<dynamic> items, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        title: Text(title, style: montserratTextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${items.length} record(s)", style: montserratTextStyle(color: Colors.grey[600])),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
