import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heavens_connect/services/auth_service.dart';
import 'package:heavens_connect/services/contribution_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/app_dialog.dart';
import '../../utils/app_theme.dart';

// keep your imports...

class ContributionDetailScreen extends StatefulWidget {
  final int contributionId;

  const ContributionDetailScreen({super.key, required this.contributionId});

  @override
  State<ContributionDetailScreen> createState() => _ContributionDetailScreenState();
}

class _ContributionDetailScreenState extends State<ContributionDetailScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? contribution;
  bool isLoading = true;

  final Color themeColor = AppTheme.themeColor;

  @override
  void initState() {
    super.initState();
    fetchContributionDetail();
  }

  Future<void> fetchContributionDetail() async {
    final data = await _authService.getContributionDetail(widget.contributionId);
    setState(() {
      contribution = data;
      isLoading = false;
    });
  }

  Future<void> openProofOfPayment() async {
    final url = Uri.parse(contribution!['proof_of_payment']);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open proof of payment', style: GoogleFonts.montserrat())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: themeColor),
        title: Text('Contribution Details', style: GoogleFonts.montserrat(color: themeColor, fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : contribution == null
          ? Center(child: Text('Contribution not found', style: GoogleFonts.montserrat()))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGlassHeader(),
            const SizedBox(height: 30),
            Text('Proof of Payment', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            contribution!['proof_of_payment'] != null ? _buildProofOfPaymentCard() : _buildNoProofCard(),
            const SizedBox(height: 30),
            if (contribution!['status'] == 'pending') _buildActionButtons(),
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
          Text(
            contribution!['member_name'] ?? '',
            style: GoogleFonts.montserrat(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _detailItem('Amount', '£${contribution!['amount']}'),
          _detailItem('Payment Method', contribution!['payment_method'].toString().capitalize()),
          _detailItem('Transaction Ref.', contribution!['transaction_ref'] ?? 'N/A'),
          _detailItem('Month', monthName(contribution!['month'])),
          _detailItem('Year', contribution!['year'].toString()),
          const SizedBox(height: 10),
          _buildStatusBadge(contribution!['status']),
          if (contribution!['rejection_reason'] != null && contribution!['rejection_reason'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Reason: ${contribution!['rejection_reason']}',
                  style: GoogleFonts.montserrat(color: Colors.redAccent, fontSize: 12)),
            ),
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
          Text(label, style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 12)),
          Text(value, style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0.0, 0.5),
          end: Offset.zero,
        ).animate(animation);

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(status),  // Important for AnimatedSwitcher
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status.toUpperCase(),
          style: GoogleFonts.montserrat(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }


  Widget _buildProofOfPaymentCard() {
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
            child: Image.network(contribution!['proof_of_payment'], height: 220, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: openProofOfPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            icon: const Icon(Icons.open_in_new, color: Colors.white),
            label: Text('View Full Proof', style: GoogleFonts.montserrat(color: Colors.white)),
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
      child: Text('No proof of payment provided.', style: GoogleFonts.montserrat(color: Colors.grey)),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _approveContribution,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size.fromHeight(50),
          ),
          icon: const Icon(Icons.check, color: Colors.white),
          label: Text('Verify Contribution', style: GoogleFonts.montserrat(color: Colors.white)),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _promptRejectReason,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size.fromHeight(50),
          ),
          icon: const Icon(Icons.close, color: Colors.white),
          label: Text('Reject', style: GoogleFonts.montserrat(color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _approveContribution() async {
    final confirm = await showConfirmDialog('Confirm Verification', 'Are you sure you want to verify this contribution?');
    if (confirm) {
      AppDialog.showLoadingDialog(context);
      final success = await _authService.verifyContribution(widget.contributionId);
      Navigator.pop(context);

      if (success) {
        await AppDialog.showSuccessDialog(context, title: 'Verified', message: 'Contribution has been verified.');
        fetchContributionDetail();
      } else {
        await AppDialog.showWarningDialog(context, title: 'Failed', message: 'Verification failed. Try again.');
      }
    }
  }

  Future<void> _promptRejectReason() async {
    final reason = await showInputReasonDialog();
    if (reason != null && reason.trim().isNotEmpty) {
      AppDialog.showLoadingDialog(context);
      final success = await _authService.rejectContribution(widget.contributionId, reason.trim());
      Navigator.pop(context);

      if (success) {
        await AppDialog.showSuccessDialog(context, title: 'Rejected', message: 'Contribution has been rejected.');
        fetchContributionDetail();
      } else {
        await AppDialog.showWarningDialog(context, title: 'Failed', message: 'Rejection failed. Try again.');
      }
    }
  }

  // ------------------- Dialog Helpers -------------------
  Future<bool> showConfirmDialog(String title, String message) async {
    bool confirmed = false;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            child: const Text('Yes'),
            onPressed: () {
              confirmed = true;
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
    return confirmed;
  }

  Future<String?> showInputReasonDialog() async {
    String? reason;
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rejection Reason'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter reason...'),
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            child: const Text('Submit'),
            onPressed: () {
              reason = controller.text;
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
    return reason;
  }
}

// ------------------- Helpers -------------------
extension StringExtension on String {
  String capitalize() => isNotEmpty ? "${this[0].toUpperCase()}${substring(1)}" : "";
}

String monthName(int month) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return months[month - 1];
}

