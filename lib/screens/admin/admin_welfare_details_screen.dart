import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heavens_connect/services/auth_service.dart';
import 'package:heavens_connect/utils/app_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/app_theme.dart';

class AdminWelfareRequestDetailScreen extends StatefulWidget {
  final dynamic request;
  const AdminWelfareRequestDetailScreen({super.key, required this.request});

  @override
  State<AdminWelfareRequestDetailScreen> createState() => _AdminWelfareRequestDetailScreenState();
}

class _AdminWelfareRequestDetailScreenState extends State<AdminWelfareRequestDetailScreen> {
  final AuthService _authService = AuthService();
  bool isProcessing = false;
  final Color themeColor = AppTheme.themeColor;

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final category = capitalize(request['category']);
    final description = request['description'];
    final amount = request['amount_requested'] != null
        ? "£${double.tryParse(request['amount_requested'].toString())?.toStringAsFixed(2)}"
        : "No amount specified";
    final status = capitalize(request['status']);
    final adminNote = request['admin_note']?.isNotEmpty == true ? request['admin_note'] : 'No note from admin';
    final requestedAt = request['requested_at']?.split('T')[0] ?? '';
    final memberName = request['member_name'] ?? 'Unknown Member';
    final attachmentUrl = request['attachment'];

    Color statusColor = _statusColor(request['status']);

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor,
        iconTheme: IconThemeData(color: themeColor),
        elevation: 0,
        title: Text('Welfare Request', style: montserratTextStyle(color: themeColor, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _glassCard([
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Request Details', style: montserratTextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  _buildStatusBadge(status, statusColor),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Member Name', memberName),
              _buildDetailRow('Category', category),
              _buildDetailRow('Description', description),
              _buildDetailRow('Amount Requested', amount),
              _buildDetailRow('Requested At', requestedAt),
              _buildDetailRow('Admin Note', adminNote),
              if (attachmentUrl != null) _buildAttachment(attachmentUrl),
            ]),
            const SizedBox(height: 24),
            if (request['status'] == 'pending' || request['status'] == 'under_review') _buildActionButtons(request),
          ],
        ),
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
          Text(label, style: montserratTextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(value, style: montserratTextStyle(fontSize: 14), softWrap: true),
        ],
      ),
    );
  }

  Widget _buildAttachment(String url) {
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
          Text('View Attachment', style: montserratTextStyle(color: themeColor, decoration: TextDecoration.underline)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: montserratTextStyle(color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,),
      ),
    );
  }

  Widget _buildActionButtons(dynamic request) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: isProcessing ? null : () => _confirmStatusChange('approved'),
                child: _gradientButton('Approve', Colors.green),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: isProcessing ? null : () => _confirmStatusChange('declined'),
                child: _gradientButton('Decline', Colors.red),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: isProcessing ? null : () => _confirmStatusChange('under_review'),
            child: _gradientButton('Mark as Under Review', themeColor),
          ),
        )
      ],
    );
  }

  Widget _gradientButton(String text, Color color) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.7), color]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 6))],
      ),
      child: Center(
        child: isProcessing && text.toLowerCase().contains('review') == false
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(text, style: montserratTextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _confirmStatusChange(String status) async {
    String note = '';
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${capitalize(status)} Request', style: montserratTextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Admin Note'),
          onChanged: (value) => note = value,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: montserratTextStyle())),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, note),
            style: ElevatedButton.styleFrom(backgroundColor: themeColor),
            child: Text('Submit', style: montserratTextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    setState(() => isProcessing = true);
    final success = await _authService.updateWelfareRequestStatus(widget.request['id'], status, result);
    setState(() => isProcessing = false);

    if (success) {
      await AppDialog.showSuccessDialog(
        context,
        title: 'Status Updated',
        message: status == 'under_review'
            ? 'Request is now marked as under review.'
            : 'The welfare request has been ${status == 'approved' ? 'approved' : 'declined'}.',
      );
      Navigator.pop(context, true);
    } else {
      await AppDialog.showWarningDialog(
        context,
        title: 'Update Failed',
        message: 'Unable to update status. Please try again.',
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'declined':
        return Colors.red;
      case 'paid':
        return themeColor;
      case 'under_review':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String capitalize(String text) => text.isNotEmpty ? '${text[0].toUpperCase()}${text.substring(1)}' : '';
}
