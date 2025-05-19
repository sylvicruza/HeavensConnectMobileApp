import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../utils/app_dialog.dart';
import '../../utils/app_theme.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final AuthService _authService = AuthService();
  final Color themeColor = AppTheme.themeColor;

  bool isLoading = true;
  Map<String, dynamic> settings = {};
  Map<String, dynamic> settingsMeta = {}; // Fill with ID info if needed

  @override
  void initState() {
    super.initState();
    fetchSettings();
  }

  Future<void> fetchSettings() async {
    setState(() => isLoading = true);
    final response = await _authService.getRawSystemSettings();
    setState(() {
      settings = response['settings'] ?? {};
      settingsMeta = response['meta'] ?? {};
      isLoading = false;
    });
  }



  Future<void> updateSetting(String key, List<String> values) async {
    final id = settingsMeta[key]?['id'];
    if (id != null) {
      await AppDialog.showLoadingDialog(context, message: 'Updating setting...');
      final success = await _authService.updateSystemSetting(id, {
        'key': key,
        'value': values.join(','),
      });
      Navigator.pop(context); // close loading

      if (success) {
        await AppDialog.showSuccessDialog(context, title: 'Updated', message: '$key updated successfully.');
        fetchSettings();
      } else {
        await AppDialog.showWarningDialog(context, title: 'Update Failed', message: 'Could not update $key.');
      }
    }
  }

  Future<void> addSetting(String key, List<String> values) async {
    Navigator.pop(context); // close the add dialog
    await AppDialog.showLoadingDialog(context, message: 'Adding setting...');
    final success = await _authService.createSystemSetting({
      'key': key,
      'value': values.join(','),
    });
    Navigator.pop(context); // close loading

    if (success) {
      await AppDialog.showSuccessDialog(context, title: 'Created', message: '$key setting added.');
      fetchSettings();
    } else {
      await AppDialog.showWarningDialog(context, title: 'Failed', message: 'Could not add new setting.');
    }
  }

  void _showEditDialog(String key, List<String> initialValues) {
    final List<String> values = List.from(initialValues);
    final TextEditingController inputController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Edit ${key.replaceAll('_', ' ')}',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: values.map((val) {
                      return Chip(
                        label: Text(val),
                        onDeleted: () {
                          setState(() => values.remove(val));
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: inputController,
                          decoration: const InputDecoration(
                            hintText: 'Add new value',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final newVal = inputController.text.trim();
                          if (newVal.isNotEmpty && !values.contains(newVal)) {
                            setState(() {
                              values.add(newVal);
                              inputController.clear();
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                        ),
                        child: const FittedBox(child: Text('Add', style: TextStyle(color: Colors.white))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: themeColor,),
              onPressed: () {
                updateSetting(key, values);
                Navigator.pop(context);
              },

              child: const FittedBox(child: Text('Save', style: TextStyle(color: Colors.white))),
            ),
          ],
        ),
      ),
    );
  }



  void _showAddDialog() {
    final TextEditingController keyController = TextEditingController();
    final TextEditingController valueInputController = TextEditingController();
    final List<String> values = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add New Setting', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: keyController,
                    decoration: const InputDecoration(labelText: 'Setting Key'),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: values.map((val) {
                      return Chip(
                        label: Text(val),
                        onDeleted: () {
                          setState(() => values.remove(val));
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: valueInputController,
                          decoration: const InputDecoration(
                            hintText: 'Add value',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final newVal = valueInputController.text.trim();
                          if (newVal.isNotEmpty && !values.contains(newVal)) {
                            setState(() {
                              values.add(newVal);
                              valueInputController.clear();
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                        ),
                        child: const FittedBox(child: Text('Add', style: TextStyle(color: Colors.white))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: themeColor),
              onPressed: () {
                final key = keyController.text.trim();
                if (key.isNotEmpty && values.isNotEmpty) {
                  addSetting(key, values);
                } else {
                  Navigator.pop(context);
                  AppDialog.showWarningDialog(context, title: 'Missing Info', message: 'Key and at least one value are required.');
                }
              },
              child: const FittedBox(child: Text('Add', style: TextStyle(color: Colors.white))),

            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('System Settings', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: themeColor)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: themeColor),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: themeColor,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchSettings,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: settings.entries.length,
          itemBuilder: (context, index) {
            final entry = settings.entries.elementAt(index);
            final key = entry.key;
            final values = entry.value;

            return GestureDetector(
              onTap: () => _showEditDialog(key, values),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      key.replaceAll('_', ' ').toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: themeColor.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: values.map<Widget>((v) {
                        return Chip(
                          label: Text(v, style: GoogleFonts.montserrat(fontSize: 12)),
                          backgroundColor: themeColor.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text('Edit',
                          style: GoogleFonts.montserrat(
                            color: themeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

      ),
    );
  }
}
