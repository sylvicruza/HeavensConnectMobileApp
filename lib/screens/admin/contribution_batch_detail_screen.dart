import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heavens_connect/services/auth_service.dart';
import 'package:heavens_connect/utils/app_dialog.dart';
import 'package:heavens_connect/utils/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ContributionBatchDetailScreen extends StatelessWidget {
  final Map<String, dynamic> batch;
  final AuthService _authService = AuthService();
  final Color themeColor = AppTheme.themeColor;

  ContributionBatchDetailScreen({super.key, required this.batch});

  Future<void> _verifyBatch(BuildContext context) async {
    AppDialog.showLoadingDialog(context);
    final success = await _authService.verifyContributionBatch(batch['batch_id']);
    Navigator.pop(context);

    if (success) {
      await AppDialog.showSuccessDialog(
        context,
        title: 'Batch Verified',
        message: 'All contributions in this batch have been verified.',
      );
      Navigator.pop(context, true);
    } else {
      await AppDialog.showWarningDialog(
        context,
        title: 'Verification Failed',
        message: 'Something went wrong while verifying.',
      );
    }
  }

  Future<void> _openProofOfPayment(BuildContext context) async {
    final url = Uri.parse(batch['proof_of_payment']);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open proof of payment', style: montserratTextStyle())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: Text('Batch Details', style: montserratTextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.appBarColor,
        iconTheme: IconThemeData(color: themeColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGlassHeader(),

            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _verifyBatch(context),
              icon: const Icon(Icons.verified, color: Colors.white),
              label: Text('Verify All', style: montserratTextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [themeColor, themeColor.withOpacity(0.8)]),
        boxShadow: [
          BoxShadow(color: themeColor.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(batch['member_name'], style: montserratTextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _detailItem('Total Amount', '£${batch['total_amount']}'),
          _detailItem('Status', batch['status'].toString().capitalize()),
          _detailItem('Months', batch['months'].join(', ')),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: montserratTextStyle(color: Colors.white70, fontSize: 12)),
          Flexible(child: Text(value, textAlign: TextAlign.end, style: montserratTextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildProofOfPaymentCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(batch['proof_of_payment'], height: 220, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _openProofOfPayment(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            icon: const Icon(Icons.open_in_new, color: Colors.white),
            label: Text('View Full Proof', style: montserratTextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoProofCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: Text('No proof of payment provided.', style: montserratTextStyle(color: Colors.grey)),
    );
  }
}

extension StringExtension on String {
  String capitalize() => isNotEmpty ? "${this[0].toUpperCase()}${substring(1)}" : "";
}
