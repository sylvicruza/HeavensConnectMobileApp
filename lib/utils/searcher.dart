import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import 'app_theme.dart';

class AdminSearchDelegate extends SearchDelegate<String> {
  final AuthService authService;

  AdminSearchDelegate({required this.authService});

  @override
  String get searchFieldLabel => 'Search members, contributions, requests...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<Map<String, List<dynamic>>>(
      future: _searchAll(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final results = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (results['members']!.isEmpty &&
                results['contributions']!.isEmpty &&
                results['requests']!.isEmpty)
              const Text('No results found'),
            ..._buildSection(
                context, 'Members', results['members']!, Icons.person, '/allMembers'),
            ..._buildSection(
                context, 'Contributions', results['contributions']!, Icons.volunteer_activism, '/contributions'),
            ..._buildSection(
                context, 'Requests', results['requests']!, Icons.request_page, '/welfareRequests'),
          ],
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(child: Text('Type to search...'));
  }

  Future<Map<String, List<dynamic>>> _searchAll(String term) async {
    if (term.trim().isEmpty) {
      return {
        'members': [],
        'contributions': [],
        'requests': [],
      };
    }

    // ---- MOCK IMPLEMENTATION ----
    // Replace these with actual API calls
    final members = await authService.searchMembers(term);
    final contributions = await authService.searchContributions(term);
    final requests = await authService.searchWelfareRequests(term);

    return {
      'members': members ?? [],
      'contributions': contributions ?? [],
      'requests': requests ?? [],
    };
  }

  List<Widget> _buildSection(
      BuildContext context, String title, List<dynamic> items, IconData icon, String route) {
    if (items.isEmpty) return [];

    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          title,
          style: GoogleFonts.montserrat(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ),
      ...items.map((item) {
        return Card(
          child: ListTile(
            leading: Icon(icon, color: AppTheme.themeColor),
            title: Text(item['full_name'] ?? item['member_name'] ?? 'No name'),
            subtitle: Text(item['email'] ?? item['status'] ?? ''),
            onTap: () {
              // In real use, navigate to the detail page with ID
              Navigator.pop(context);
              Navigator.pushNamed(context, route);
            },
          ),
        );
      }).toList()
    ];
  }
}
