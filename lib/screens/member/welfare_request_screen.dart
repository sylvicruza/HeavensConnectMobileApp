import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heavens_connect/services/auth_service.dart';
import 'package:heavens_connect/utils/setting_keys.dart';
import 'package:image_picker/image_picker.dart';

import '../../utils/app_dialog.dart';
import '../../utils/app_theme.dart';

class MemberWelfareRequestScreen extends StatefulWidget {
  const MemberWelfareRequestScreen({super.key});

  @override
  State<MemberWelfareRequestScreen> createState() => _MemberWelfareRequestScreenState();
}

class _MemberWelfareRequestScreenState extends State<MemberWelfareRequestScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  List<String> categories = [];
  String selectedCategory = 'medical';
  File? attachment;
  bool isSubmitting = false;

  final Color themeColor = AppTheme.themeColor;

  @override
  void initState() {
    super.initState();
    _loadSystemSettings();
  }

  Future<void> _loadSystemSettings() async {
    final settings = await _authService.getSystemSettings();
    setState(() {
      categories = settings[SettingKeys.categories]?.cast<String>() ?? [
        'school_fees',
        'marriage',
        'funeral',
        'job_loss',
        'medical',
        'baby_dedication',
        'food',
        'rent',
        'others',
      ];
      selectedCategory = categories.contains(selectedCategory) ? selectedCategory : categories.first;
    });
  }

  Future<void> pickAttachment() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => attachment = File(pickedFile.path));
    }
  }

  Future<void> submitRequest() async {
    if (descriptionController.text.isEmpty) {
      await AppDialog.showWarningDialog(context, title: 'Missing Info', message: 'Description is required');
      return;
    }

    AppDialog.showLoadingDialog(context);

    final success = await _authService.submitWelfareRequest({
      'category': selectedCategory,
      'description': descriptionController.text,
      'amount_requested': amountController.text.isNotEmpty ? amountController.text : null,
    }, attachment: attachment);

    Navigator.pop(context); // close loading

    if (success) {
      await AppDialog.showSuccessDialog(context, title: 'Submitted', message: 'Welfare request submitted successfully');
      Navigator.pop(context, true);
    } else {
      await AppDialog.showWarningDialog(context, title: 'Failed', message: 'Failed to submit request');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: Text('Welfare Request', style: GoogleFonts.montserrat(color: themeColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: themeColor),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCardWrapper(_buildCategoryDropdown()),
          const SizedBox(height: 16),
          _buildCardWrapper(_buildTextField('Description', descriptionController, maxLines: 4)),
          const SizedBox(height: 16),
          _buildCardWrapper(_buildTextField('Amount Requested (£) - optional', amountController, inputType: TextInputType.number)),
          const SizedBox(height: 16),
          _buildCardWrapper(_buildAttachmentPicker()),
          const SizedBox(height: 30),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  /// UI Wrappers
  Widget _buildCardWrapper(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedCategory,
      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c.replaceAll('_', ' ').toUpperCase(), style: GoogleFonts.montserrat()))).toList(),
      onChanged: (value) => setState(() => selectedCategory = value!),
      decoration: InputDecoration(
        labelText: 'Select Category',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(Icons.category, color: themeColor),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, {TextInputType? inputType, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: hint.contains('Amount') ? Icon(Icons.attach_money, color: themeColor) : null,
      ),
    );
  }

  Widget _buildAttachmentPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attachment (optional)', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: pickAttachment,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: Text('Upload', style: GoogleFonts.montserrat(color: Colors.white)),
            ),
            const SizedBox(width: 12),
            if (attachment != null) Text('File Selected', style: GoogleFonts.montserrat(color: Colors.green)),
          ],
        )
      ],
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: isSubmitting ? null : submitRequest,
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [themeColor, themeColor.withOpacity(0.8)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: themeColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 6))],
        ),
        child: Center(
          child: isSubmitting
              ? const CircularProgressIndicator(color: Colors.white)
              : Text('Submit Request', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

String capitalize(String text) => text.isNotEmpty ? '${text[0].toUpperCase()}${text.substring(1)}' : '';
