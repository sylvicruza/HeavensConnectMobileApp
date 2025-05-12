import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../utils/app_dialog.dart';
import '../../utils/app_theme.dart';

class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({super.key});

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  final AuthService _authService = AuthService();
  List<dynamic> pendingRequests = [];
  bool isLoading = true;

  final Color themeColor = AppTheme.themeColor; // Faithful Purple

  @override
  void initState() {
    super.initState();
    fetchPendingRequests();
  }

  Future<void> fetchPendingRequests() async {
    setState(() => isLoading = true);
    final data = await _authService.getPendingRequests();
    setState(() {
      pendingRequests = data ?? [];
      isLoading = false;
    });
  }

  Future<void> _approve(int id) async {
    AppDialog.showLoadingDialog(context);
    final success = await _authService.approveRequest(id);
    Navigator.pop(context);
    if (success) {
      await AppDialog.showSuccessDialog(context, title: 'Request Approved');
      fetchPendingRequests();
    } else {
      await AppDialog.showWarningDialog(context, title: 'Approval Failed', message: 'Something went wrong.');
    }
  }

  Future<void> _reject(int id) async {
    String? reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final TextEditingController reasonController = TextEditingController();
        return AlertDialog(
          title: const Text('Reject Request'),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Enter rejection reason...'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final reason = reasonController.text.trim();
                if (reason.isNotEmpty) Navigator.pop(context, reason);
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (reason != null) {
      AppDialog.showLoadingDialog(context);
      final success = await _authService.rejectRequest(id, reason);
      Navigator.pop(context);
      if (success) {
        await AppDialog.showSuccessDialog(context, title: 'Request Rejected');
        fetchPendingRequests();
      } else {
        await AppDialog.showWarningDialog(context, title: 'Rejection Failed', message: 'Something went wrong.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: themeColor),
        title: Text('Pending Membership', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: themeColor)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pendingRequests.isEmpty
          ? Center(child: Text('No pending membership request', style: GoogleFonts.montserrat()))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pendingRequests.length,
        itemBuilder: (context, index) => _buildRequestCard(pendingRequests[index]),
      ),
    );
  }

  Widget _buildRequestCard(dynamic request) {
    final String fullName = request['full_name']?.toString() ?? '';
    final String phoneNumber = request['phone_number']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildGradientAvatar(request),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fullName, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(phoneNumber, style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildActionButton('Approve', Colors.green, () => _approve(request['id']))),
                const SizedBox(width: 8),
                Expanded(child: _buildActionButton('Reject', Colors.redAccent, () => _reject(request['id']))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientAvatar(dynamic request) {
    final String name = (request['full_name'] ?? '').toString();
    final String? profilePicture = request['profile_picture'];

    if (profilePicture != null && profilePicture.isNotEmpty) {
      return CircleAvatar(radius: 24, backgroundImage: NetworkImage(profilePicture));
    } else {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [themeColor, themeColor.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '',
            style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      );
    }
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        side: BorderSide(color: color, width: 1.5),
        backgroundColor: Colors.white,
      ),
      child: Text(label, style: GoogleFonts.montserrat(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}
