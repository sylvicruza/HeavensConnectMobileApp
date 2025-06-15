import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heavens_connect/services/auth_service.dart';
import 'package:heavens_connect/utils/app_theme.dart';

class ContributionBatchListScreen extends StatefulWidget {
  const ContributionBatchListScreen({super.key});

  @override
  State<ContributionBatchListScreen> createState() => _ContributionBatchListScreenState();
}

class _ContributionBatchListScreenState extends State<ContributionBatchListScreen> {
  final AuthService _authService = AuthService();
  final Color themeColor = AppTheme.themeColor;
  List<dynamic> batches = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBatches();
  }

  Future<void> fetchBatches() async {
    setState(() => isLoading = true);
    final response = await _authService.getPendingContributionBatches(); // <-- Add this API method
    setState(() {
      batches = response ?? [];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pending Contribution Batches', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: themeColor),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : batches.isEmpty
          ? Center(child: Text('No pending batches.', style: GoogleFonts.montserrat()))
          : ListView.builder(
        itemCount: batches.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final batch = batches[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              title: Text(batch['member_name'], style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text("£${batch['total_amount']} across ${batch['months'].length} months",
                      style: GoogleFonts.montserrat()),
                  Text("Months: ${batch['months'].join(', ')}", style: GoogleFonts.montserrat(fontSize: 12)),
                ],
              ),
              trailing: Icon(Icons.chevron_right, color: themeColor),
              onTap: () {
                Navigator.pushNamed(context, '/batchDetail', arguments: batch);
              },
            ),
          );
        },
      ),
    );
  }
}
