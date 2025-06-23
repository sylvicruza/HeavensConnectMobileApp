import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/member_bottom_nav.dart';

class MemberWelfareRequestListScreen extends StatefulWidget {
  const MemberWelfareRequestListScreen({super.key});

  @override
  State<MemberWelfareRequestListScreen> createState() => _MemberWelfareRequestListScreenState();
}

class _MemberWelfareRequestListScreenState extends State<MemberWelfareRequestListScreen> {
  final AuthService _authService = AuthService();
  List<dynamic> welfareRequests = [];
  List<dynamic> filteredRequests = [];
  bool isLoading = true;
  final Color themeColor = AppTheme.themeColor;

  Timer? _debounce;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    setState(() => isLoading = true);
    final profile = await _authService.getMemberProfile();
    if (profile != null) {
      final data = await _authService.getWelfareRequestsByUsername(profile['username']);
      setState(() {
        welfareRequests = data ?? [];
        filteredRequests = welfareRequests; // Initialize filtered list
        isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        searchQuery = value.toLowerCase();
        filteredRequests = welfareRequests.where((req) {
          final category = req['category']?.toString().toLowerCase() ?? '';
          final status = req['status']?.toString().toLowerCase() ?? '';
          return category.contains(searchQuery) || status.contains(searchQuery);
        }).toList();
      });
    });
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
        elevation: 1,
        iconTheme: IconThemeData(color: themeColor),
        title: Text('Welfare Requests', style: montserratTextStyle(fontWeight: FontWeight.bold, color: themeColor)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by category or status...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: filteredRequests.isEmpty
                ? Center(child: Text('No welfare requests found', style: montserratTextStyle()))
                : RefreshIndicator(
              onRefresh: fetchRequests,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredRequests.length,
                itemBuilder: (context, index) {
                  final request = filteredRequests[index];
                  return _buildRequestCard(request);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: themeColor,
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/memberSubmitWelfareRequest');
          if (result == true) fetchRequests(); // Refresh on return
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: MemberBottomNavBar(selectedIndex: 2),


    );
  }

  Widget _buildRequestCard(dynamic request) {
    final category = capitalize(request['category'] ?? 'Unknown');
    final status = request['status'] ?? 'pending';
    final amount = request['amount_requested'] != null
        ? "£${double.tryParse(request['amount_requested'].toString())?.toStringAsFixed(2)}"
        : "No amount";
    final requestedAt = request['requested_at']?.split('T')[0] ?? '';

    Color statusColor;
    switch (status) {
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

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: ListTile(
        title: Text(category, style: montserratTextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(amount, style: montserratTextStyle(color: themeColor, fontWeight: FontWeight.w500)),
            Text('Requested: $requestedAt', style: montserratTextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(capitalize(status), style: montserratTextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
        onTap: () {
          Navigator.pushNamed(context, '/memberWelfareRequestDetail', arguments: request)
              .then((value) {
            if (value == true) {
              fetchRequests();  // Refresh list if request was edited/deleted
            }
          });
        },
      ),
    );
  }

  String capitalize(String text) => text.isNotEmpty ? '${text[0].toUpperCase()}${text.substring(1)}' : '';
}
