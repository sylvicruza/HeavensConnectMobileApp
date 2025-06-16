import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heavens_connect/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/app_dialog.dart';
import '../../utils/app_theme.dart';

class MemberWelfareRequestDetailScreen extends StatefulWidget {
  final dynamic request;
  const MemberWelfareRequestDetailScreen({super.key, required this.request});

  @override
  State<MemberWelfareRequestDetailScreen> createState() => _MemberWelfareRequestDetailScreenState();
}

class _MemberWelfareRequestDetailScreenState extends State<MemberWelfareRequestDetailScreen> {
  final AuthService _authService = AuthService();
  bool isDeleting = false;
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
    final adminNote = request['admin_note'] ?? 'No note from admin';
    final requestedAt = request['requested_at']?.split('T')[0] ?? '';
    final attachmentUrl = request['attachment'];

    Color statusColor;
    switch (request['status']) {
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

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor,
        iconTheme: IconThemeData(color: themeColor),
        elevation: 0,
        title: Text('Welfare Request', style: montserratTextStyle(color: themeColor, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _glassCard([
              _buildDetailRow('Category', category),
              _buildDetailRow('Description', description),
              _buildDetailRow('Amount Requested', amount),
              _buildDetailRow('Requested At', requestedAt),
              _buildDetailRow('Admin Note', adminNote),
              if (attachmentUrl != null) _buildAttachment(attachmentUrl),
              const SizedBox(height: 20),
              _buildStatusBadge(status, statusColor),
            ]),
            const Spacer(),
            if (request['status'] == 'pending') _buildActionButtons(request),
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
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 6)),
        ],
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
          Text(
            value,
            style: montserratTextStyle(fontSize: 14),
            textAlign: TextAlign.start,
            softWrap: true,
          ),
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
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.7), color]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(status, style: montserratTextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildActionButtons(dynamic request) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final result = await Navigator.pushNamed(context, '/editWelfareRequest', arguments: request);
              if (result == true) Navigator.pop(context, true);
            },
            child: _gradientButton('Edit', themeColor),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: isDeleting ? null : _confirmDelete,
            child: _gradientButton('Delete', Colors.red),
          ),
        ),
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
        child: isDeleting && text == 'Delete'
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(text, style: montserratTextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete', style: montserratTextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this request?', style: montserratTextStyle()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: montserratTextStyle())),
          ElevatedButton(
            onPressed: _deleteRequest,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: montserratTextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRequest() async {
    Navigator.pop(context); // Close dialog
    setState(() => isDeleting = true);

    final success = await _authService.deleteWelfareRequest(widget.request['id']);

    setState(() => isDeleting = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      await AppDialog.showWarningDialog(context, title: 'Delete Failed', message: 'Unable to delete the request. Please try again.');
    }
  }

  String capitalize(String text) => text.isNotEmpty ? '${text[0].toUpperCase()}${text.substring(1)}' : '';
}
