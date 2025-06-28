import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:excel/excel.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart'; // Add this package too
import '../../../services/auth_service.dart';
import '../../../utils/app_dialog.dart';
import '../../../utils/app_theme.dart';

class ImportLegacyContributionsScreen extends StatefulWidget {
  const ImportLegacyContributionsScreen({super.key});

  @override
  State<ImportLegacyContributionsScreen> createState() => _ImportLegacyContributionsScreenState();
}

class _ImportLegacyContributionsScreenState extends State<ImportLegacyContributionsScreen> {
  final AuthService _authService = AuthService();
  File? selectedFile;
  List<Map<String, dynamic>> parsedRows = [];
  List<String> validationErrors = [];

  Future<void> _pickExcelFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);

    if (result != null && result.files.single.path != null) {
      final fileBytes = File(result.files.single.path!).readAsBytesSync();
      final excel = Excel.decodeBytes(fileBytes);
      final sheet = excel.tables[excel.tables.keys.first];

      parsedRows.clear();
      validationErrors.clear();

      if (sheet != null) {
        for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
          final row = sheet.row(rowIndex);
          final fullName = row[0]?.value.toString().trim() ?? '';
          final amount = double.tryParse(row[1]?.value.toString() ?? '');
          final month = int.tryParse(row[2]?.value.toString() ?? '');
          final year = int.tryParse(row[3]?.value.toString() ?? '');
          final method = row[4]?.value.toString().trim().toLowerCase();

          final errors = <String>[];
          if (fullName.isEmpty) errors.add("Missing full name");
          if (amount == null || amount <= 0) errors.add("Invalid amount");
          if (month == null || month < 1 || month > 12) errors.add("Invalid month");
          if (year == null || year < 2000) errors.add("Invalid year");
          if (method != 'cash' && method != 'transfer') errors.add("Invalid payment method");

          if (errors.isNotEmpty) {
            validationErrors.add("Row ${rowIndex + 1}: ${errors.join(', ')}");
          }

          parsedRows.add({
            'full_name': fullName,
            'amount': amount,
            'month': month,
            'year': year,
            'payment_method': method,
          });
        }
      }

      setState(() {
        selectedFile = File(result.files.single.path!);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationErrors.isEmpty
              ? 'File parsed and ready.'
              : 'File parsed with ${validationErrors.length} validation issue(s).'),
        ),
      );
    }
  }

  Future<void> _submitImport() async {
    if (selectedFile == null) return;
    if (validationErrors.isNotEmpty) {
      await AppDialog.showWarningDialog(
        context,
        title: 'Validation Failed',
        message: 'Please fix the highlighted errors before importing.',
      );
      return;
    }

    AppDialog.showLoadingDialog(context, message: 'Uploading legacy contributions...');
    final success = await _authService.importLegacyContributionsExcel(selectedFile!);
    Navigator.pop(context);

    if (success) {
      await AppDialog.showSuccessDialog(
        context,
        title: 'Import Successful',
        message: 'Legacy contributions have been successfully imported.',
      );
      Navigator.pop(context);
    } else {
      await AppDialog.showWarningDialog(
        context,
        title: 'Import Failed',
        message: 'Something went wrong. Please check the Excel file or try again.',
      );
    }
  }

  void _downloadTemplate() async {
    // Request permission (required on Android)
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission denied.')),
      );
      return;
    }

    final ByteData data = await rootBundle.load('assets/files/legacy_template.xlsx');
    final bytes = data.buffer.asUint8List();

    final directory = await getExternalStorageDirectory();
    final downloadsPath = '${directory!.path}/legacy_template.xlsx';

    final file = File(downloadsPath);
    await file.writeAsBytes(bytes, flush: true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Template saved to: $downloadsPath')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Import Contributions', style: montserratTextStyle(fontWeight: FontWeight.bold, color: AppTheme.themeColor)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadTemplate,
            tooltip: 'Download Excel Template',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Select Excel File (.xlsx)'),
              onPressed: _pickExcelFile,
            ),
            const SizedBox(height: 20),
            if (parsedRows.isNotEmpty)
              const Text('Preview:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (parsedRows.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: parsedRows.length,
                  itemBuilder: (context, index) {
                    final item = parsedRows[index];
                    return ListTile(
                      title: Text('${item['full_name']} - £${item['amount']}'),
                      subtitle: Text('${item['month']}/${item['year']} - ${item['payment_method']}'),
                      trailing: validationErrors.any((e) => e.contains('Row ${index + 2}'))
                          ? const Icon(Icons.warning, color: Colors.red)
                          : const Icon(Icons.check_circle, color: Colors.green),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            if (selectedFile != null)
              ElevatedButton(
                onPressed: _submitImport,
                child: const Text('Import Contributions'),
              )
          ],
        ),
      ),
    );
  }
}
