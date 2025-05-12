import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/app_theme.dart';

class AdminDisbursementDetailScreen extends StatelessWidget {
  final dynamic disbursement;
  const AdminDisbursementDetailScreen({super.key, required this.disbursement});

  @override
  Widget build(BuildContext context) {
    final themeColor = AppTheme.themeColor;
    final recipient = disbursement['member_name'] ?? 'Unregistered Recipient';
    final amount = "£${disbursement['amount'].toString()}";
    final category = capitalize(disbursement['category'] ?? '');
    final method = capitalize(disbursement['payment_method'] ?? '');
    final date = disbursement['disbursed_at']?.split('T')[0] ?? '';
    final description = disbursement['description'] ?? 'No description';
    final attachmentUrl = disbursement['attachment'];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: themeColor),
        title: Text('Disbursement Detail', style: GoogleFonts.montserrat(color: themeColor, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _glassCard([
          _buildDetailRow('Recipient', recipient),
          _buildDetailRow('Amount', amount),
          _buildDetailRow('Category', category),
          _buildDetailRow('Payment Method', method),
          _buildDetailRow('Disbursed At', date),
          _buildDetailRow('Description', description),
          if (attachmentUrl != null) _buildAttachment(attachmentUrl, themeColor),
        ]),
      ),
    );
  }

  Widget _glassCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white, Colors.white.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.montserrat(fontSize: 14), textAlign: TextAlign.start),
        ],
      ),
    );
  }

  Widget _buildAttachment(String url, Color color) {
    return GestureDetector(
      onTap: () async {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      },
      child: Row(
        children: [
          const Icon(Icons.attach_file, color: Colors.grey),
          const SizedBox(width: 6),
          Text('View Attachment', style: GoogleFonts.montserrat(color: color, decoration: TextDecoration.underline)),
        ],
      ),
    );
  }

  String capitalize(String text) => text.isNotEmpty ? '${text[0].toUpperCase()}${text.substring(1)}' : '';
}
