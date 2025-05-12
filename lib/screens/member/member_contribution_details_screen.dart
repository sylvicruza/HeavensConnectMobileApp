import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/app_theme.dart';

class MemberContributionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> contribution;
  final Color themeColor = AppTheme.themeColor;

  MemberContributionDetailScreen({super.key, required this.contribution});

  @override
  Widget build(BuildContext context) {
    final amount = contribution['amount']?.toString() ?? '0.00';
    final paymentMethod = capitalize(contribution['payment_method'] ?? '');
    final status = contribution['status'] ?? 'pending';
    final transactionRef = contribution['transaction_ref'] ?? 'N/A';
    final month = monthName(contribution['month']);
    final year = contribution['year']?.toString() ?? '';
    final createdAt = (contribution['created_at'] ?? '').split('T')[0];
    final proofImageUrl = contribution['proof_of_payment'];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: themeColor),
        title: Text('Contribution Details',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: themeColor)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGlassHeader(amount, status),
          const SizedBox(height: 24),
          _detailTile('Payment Method', paymentMethod),
          _detailTile('Transaction Ref.', transactionRef),
          _detailTile('For Month', '$month $year'),
          _detailTile('Submitted On', createdAt),
          const SizedBox(height: 24),
          Text('Proof of Payment', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          proofImageUrl != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(proofImageUrl, fit: BoxFit.cover, height: 220, width: double.infinity),
          )
              : Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('No proof of payment uploaded.',
                style: GoogleFonts.montserrat(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  /// Glassmorphic Header for Balance and Status
  Widget _buildGlassHeader(String amount, String status) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [themeColor, themeColor.withOpacity(0.8)]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: themeColor.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Amount', style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Text('£$amount',
                  style: GoogleFonts.montserrat(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildStatusBadge(status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Text(capitalize(status),
          style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  String capitalize(String text) => text.isNotEmpty ? '${text[0].toUpperCase()}${text.substring(1)}' : '';

  String monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
