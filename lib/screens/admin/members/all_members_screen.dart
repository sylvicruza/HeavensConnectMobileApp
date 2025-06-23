import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_dialog.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/admin_bottom_nav.dart';
import 'edit_member_screen.dart';
import 'view_member_screen.dart';

class AllMembersScreen extends StatefulWidget {
  const AllMembersScreen({super.key});

  @override
  State<AllMembersScreen> createState() => _AllMembersScreenState();
}

class _AllMembersScreenState extends State<AllMembersScreen> {
  final AuthService _authService = AuthService();
  List<dynamic> members = [];
  bool isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchMembers();
  }

  Future<void> fetchMembers() async {
    final data = await _authService.getAllMembers();
    setState(() {
      members = data ?? [];
      isLoading = false;
    });
  }

  Future<void> deleteMember(int memberId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this member?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
          ]),
    );

    if (confirmed == true) {
      final success = await _authService.deleteMember(memberId);
      if (success) {
        await AppDialog.showSuccessDialog(context, title: 'Deleted', message: 'Member deleted successfully.');
        fetchMembers();
      } else {
        await AppDialog.showWarningDialog(context, title: 'Failed', message: 'Failed to delete member.');
      }
    }
  }

  List<dynamic> get filteredMembers {
    if (_searchQuery.isEmpty) return members;
    return members.where((member) =>
    member['full_name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
        member['phone_number'].contains(_searchQuery)).toList();
  }

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.deepPurple;

    return Scaffold(
      appBar: AppBar(
        title: Text('All Members', style: montserratTextStyle(fontWeight: FontWeight.bold, color: themeColor)),
        backgroundColor: AppTheme.appBarColor,
        elevation: 1,
        iconTheme: IconThemeData(color: themeColor),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search members...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredMembers.length,
              itemBuilder: (context, index) {
                final member = filteredMembers[index];
                return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () async {
                        final refreshed = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ViewMemberScreen(member: member)),
                        );
                        if (refreshed == true) fetchMembers();
                      },
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        leading: member['profile_picture'] != null && member['profile_picture'].isNotEmpty
                            ? CircleAvatar(
                          backgroundImage: NetworkImage(member['profile_picture']),
                          radius: 28,
                        )
                            : CircleAvatar(
                          backgroundColor: themeColor.shade100,
                          radius: 28,
                          child: Text(
                            member['full_name'][0].toUpperCase(),
                            style: TextStyle(color: themeColor, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(member['full_name'], style: montserratTextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(member['phone_number'], style: montserratTextStyle(color: Colors.grey.shade600)),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'view') {
                              final refreshed = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ViewMemberScreen(member: member)),
                              );
                              if (refreshed == true) fetchMembers();
                            } else if (value == 'edit') {
                              final refreshed = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => EditMemberScreen(member: member)),
                              );
                              if (refreshed == true) fetchMembers();
                            } else if (value == 'delete') {
                              deleteMember(member['id']);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'view', child: Text('View')),
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ),
                    ));
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: themeColor,
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
        onPressed: () async {
          final refreshed = await Navigator.pushNamed(context, '/addMember');
          if (refreshed == true) fetchMembers();
        },
      ),
      bottomNavigationBar: const AdminBottomNavBar(),
      backgroundColor: AppTheme.lightBackground,
    );
  }
}
