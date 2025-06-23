import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heavens_connect/services/auth_service.dart';
import 'package:heavens_connect/utils/app_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:heavens_connect/utils/setting_keys.dart';
import '../../../utils/app_theme.dart';

class AddDisbursementScreen extends StatefulWidget {
  const AddDisbursementScreen({super.key});

  @override
  State<AddDisbursementScreen> createState() => _AddDisbursementScreenState();
}

class _AddDisbursementScreenState extends State<AddDisbursementScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController recipientNameController = TextEditingController();
  final TextEditingController recipientPhoneController = TextEditingController();

  String? selectedRequestId;
  int? selectedMemberId;
  String? category;
  String? paymentMethod;
  File? attachmentFile;

  List<dynamic> approvedRequests = [];
  List<dynamic> members = [];

  Map<String, List<String>> systemSettings = {};
  List<String> categories = [];
  List<String> paymentMethods = [];
  bool settingsLoading = true;

  final Color themeColor = AppTheme.themeColor;

  @override
  void initState() {
    super.initState();
    loadInitialData();
    _loadSystemSettings();
  }

  Future<void> _loadSystemSettings() async {
    final settings = await _authService.getSystemSettings();
    setState(() {
      systemSettings = settings;
      categories = settings[SettingKeys.categories] ?? [];
      paymentMethods = settings[SettingKeys.paymentMethods] ?? [];
      settingsLoading = false;
    });
  }

  Future<void> loadInitialData() async {
    final reqs = await _authService.getWelfareRequests(status: 'approved');
    final mems = await _authService.getAllMembers();
    setState(() {
      approvedRequests = reqs ?? [];
      members = mems ?? [];
    });
  }

  void autofillFromRequest(String requestId) {
    final request = approvedRequests.firstWhere((r) => r['id'].toString() == requestId);
    setState(() {
      selectedRequestId = requestId;
      selectedMemberId = request['member_id'];
      category = request['category'];
      amountController.text = request['amount_requested'].toString();
      descriptionController.text = request['description'] ?? '';
      recipientNameController.text = request['member_name'] ?? '';
      recipientPhoneController.text = '';
    });
  }

  Future<void> pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null) {
      setState(() {
        attachmentFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> submitDisbursement() async {
    if (!_formKey.currentState!.validate()) return;

    AppDialog.showLoadingDialog(context);

    final payload = {
      'member': selectedMemberId?.toString(),
      'request': selectedRequestId,
      'category': category,
      'amount': amountController.text.trim(),
      'description': descriptionController.text.trim(),
      'payment_method': paymentMethod,
      'recipient_name': selectedMemberId == null ? recipientNameController.text.trim() : null,
      'recipient_phone': selectedMemberId == null ? recipientPhoneController.text.trim() : null,
    };

    final success = await _authService.addDisbursement(payload, attachment: attachmentFile);

    Navigator.pop(context); // Close loading

    if (success) {
      await AppDialog.showSuccessDialog(
        context,
        title: 'Disbursement Successful!',
        message: 'Funds have been disbursed.',
      );
      Navigator.pop(context, true);
    } else {
      await AppDialog.showWarningDialog(
        context,
        title: 'Failed',
        message: 'Please try again.',
      );
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    recipientNameController.dispose();
    recipientPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: Text('New Disbursement',
            style: montserratTextStyle(color: themeColor, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: themeColor),
        backgroundColor: AppTheme.appBarColor,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              _sectionTitle("Linked Request (optional)"),
              _buildCard(DropdownButtonFormField(
                value: selectedRequestId,
                items: approvedRequests.map((req) {
                  return DropdownMenuItem(
                    value: req['id'].toString(),
                    child: Text('${req['member_name']} - £${req['amount_requested']}'),
                  );
                }).toList(),
                onChanged: (val) => autofillFromRequest(val!),
                decoration: _inputDecoration('Select Approved Welfare Request'),
              )),

              _sectionTitle("Recipient Details"),
              _buildCard(Column(
                children: [
                  DropdownButtonFormField(
                    value: selectedMemberId?.toString(),
                    items: members.map((m) {
                      return DropdownMenuItem(
                          value: m['id'].toString(), child: Text(m['full_name']));
                    }).toList(),
                    onChanged: selectedRequestId == null
                        ? (val) => setState(() => selectedMemberId = int.tryParse(val as String))
                        : null,
                    decoration: _inputDecoration('Select Member (optional)'),
                  ),
                  if (selectedMemberId == null) ...[
                    const SizedBox(height: 12),
                    _buildTextField(recipientNameController, 'Recipient Name', required: true),
                    const SizedBox(height: 12),
                    _buildTextField(recipientPhoneController, 'Recipient Phone'),
                  ]
                ],
              )),

              _sectionTitle("Disbursement Details"),
              _buildCard(Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: category,
                    items: settingsLoading
                        ? []
                        : categories.map((c) => DropdownMenuItem<String>(
                      value: c,
                      child: Text(c.replaceAll('_', ' ').toUpperCase()),
                    )).toList(),
                    onChanged: selectedRequestId == null
                        ? (val) => setState(() => category = val)
                        : null,
                    decoration: _inputDecoration('Category'),
                    validator: (val) => val == null ? 'Select a category' : null,
                  ),

                  const SizedBox(height: 12),
                  _buildTextField(amountController, 'Amount (£)', required: true, type: TextInputType.number),
                  const SizedBox(height: 12),
                  _buildTextField(descriptionController, 'Description', maxLines: 3),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    items: settingsLoading
                        ? []
                        : paymentMethods.map((p) => DropdownMenuItem<String>(
                      value: p,
                      child: Text(p.toUpperCase()),
                    )).toList(),
                    onChanged: (val) => setState(() => paymentMethod = val),
                    decoration: _inputDecoration('Payment Method'),
                    validator: (val) => val == null ? 'Select payment method' : null,
                  ),

                ],
              )),

              _sectionTitle("Attachment"),
              _buildCard(Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: pickAttachment,
                    icon: const Icon(Icons.attach_file, color: Colors.white38),
                    label: const Text('Attach Receipt', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor.withOpacity(0.8)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(
                          attachmentFile != null
                              ? attachmentFile!.path.split('/').last
                              : 'No file selected',
                          style: montserratTextStyle(fontSize: 12))),
                ],
              )),

              _buildSummaryCard(),

              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: montserratTextStyle(fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],),
      ),
    );
  }

  Widget _buildCard(Widget child) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool required = false, TextInputType? type, int? maxLines}) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines ?? 1,
      decoration: _inputDecoration(label),
      validator: required ? (val) => (val == null || val.isEmpty) ? 'Required' : null : null,
    );
  }

  Widget _buildSummaryCard() {
    final recipient = selectedMemberId != null
        ? members.firstWhere(
          (m) => m['id'] == selectedMemberId,
      orElse: () => {'full_name': 'Unknown Member'},
    )['full_name']
        : recipientNameController.text.trim().isNotEmpty
        ? recipientNameController.text.trim()
        : 'Not specified';

    final amount = amountController.text.trim().isNotEmpty
        ? '£${amountController.text.trim()}'
        : 'Amount not set';

    final payMethod = paymentMethod?.toUpperCase() ?? 'Not selected';

    return _buildCard(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Summary',
            style: montserratTextStyle(fontWeight: FontWeight.bold,
                fontSize: 16,
                color: themeColor)),
        const SizedBox(height: 8),
        Text('Recipient: $recipient'),
        Text('Amount: $amount'),
        Text('Payment Method: $payMethod'),
      ],
    ));
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: submitDisbursement,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [themeColor, themeColor.withOpacity(0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              'Submit Disbursement',
              style: montserratTextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
