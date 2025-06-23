import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heavens_connect/services/auth_service.dart';
import 'package:heavens_connect/utils/setting_keys.dart';
import 'package:image_picker/image_picker.dart';
import '../../../utils/app_dialog.dart';
import '../../../utils/app_theme.dart';

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
  String selectedCategory = 'school_fees';
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
        'school_fees', 'marriage', 'funeral', 'job_loss',
        'medical', 'baby_dedication', 'food', 'rent', 'others',
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

    setState(() => isSubmitting = true);
    AppDialog.showLoadingDialog(context);

    final success = await _authService.submitWelfareRequest({
      'category': selectedCategory,
      'description': descriptionController.text,
      'amount_requested': amountController.text.isNotEmpty ? amountController.text : null,
    }, attachment: attachment);

    Navigator.pop(context); // close loading
    setState(() => isSubmitting = false);

    if (success) {
      await AppDialog.showSuccessDialog(context, title: 'Submitted', message: 'You submitted a welfare request.\n\nYour request is pending review and will reflect once approved.');
      Navigator.pushReplacementNamed(context, '/memberWelfareRequests');
    } else {
      await AppDialog.showWarningDialog(context, title: 'Failed', message: 'Failed to submit request');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: Text('Welfare Request', style: montserratTextStyle(color: themeColor, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.appBarColor,
        elevation: 0,
        iconTheme: IconThemeData(color: themeColor),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildGlassCard(_buildCategoryDropdown()),
            const SizedBox(height: 16),
            _buildGlassCard(_buildTextField('Description', descriptionController, maxLines: 4)),
            const SizedBox(height: 16),
            _buildGlassCard(_buildTextField('Amount Requested (£) - optional', amountController, inputType: TextInputType.number)),
            const SizedBox(height: 16),
            _buildGlassCard(_buildAttachmentPicker()),
            const SizedBox(height: 30),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedCategory,
      items: categories.map((c) {
        return DropdownMenuItem(
          value: c,
          child: Row(
            children: [
              Icon(categoryIcons[c] ?? Icons.category, color: themeColor, size: 20),
              const SizedBox(width: 8),
              Text(c.replaceAll('_', ' ').toUpperCase(), style: montserratTextStyle()),
            ],
          ),
        );
      }).toList(),

      onChanged: (value) => setState(() => selectedCategory = value!),
      decoration: InputDecoration(
        labelText: 'Select Category',
        labelStyle: montserratTextStyle(),
        prefixIcon: Icon(Icons.category, color: themeColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeColor, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, {TextInputType? inputType, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      maxLines: maxLines,
      style: montserratTextStyle(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: montserratTextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeColor, width: 1.5),
        ),
        prefixIcon: hint.contains('Amount') ? Icon(Icons.attach_money, color: themeColor) : null,
      ),
    );
  }

  Widget _buildAttachmentPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attachment (optional)', style: montserratTextStyle(fontWeight: FontWeight.bold)),
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
              label: Text('Upload', style: montserratTextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 12),
            if (attachment != null)
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 6),
                  Text('File Selected', style: montserratTextStyle(color: Colors.green)),
                ],
              ),
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
              : Text('Submit Request', style: montserratTextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

String capitalize(String text) => text.isNotEmpty ? '${text[0].toUpperCase()}${text.substring(1)}' : '';

final Map<String, IconData> categoryIcons = {
  'school_fees': Icons.school,
  'marriage': Icons.favorite,
  'funeral': Icons.emoji_people,
  'job_loss': Icons.work_off,
  'medical': Icons.local_hospital,
  'baby_dedication': Icons.child_friendly,
  'food': Icons.fastfood,
  'rent': Icons.house,
  'others': Icons.more_horiz,
};
