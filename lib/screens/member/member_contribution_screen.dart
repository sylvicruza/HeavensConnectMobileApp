import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heavens_connect/services/auth_service.dart';
import 'package:heavens_connect/services/contribution_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:heavens_connect/utils/app_dialog.dart';

import '../../utils/app_theme.dart';

class MemberContributionScreen extends StatefulWidget {
  const MemberContributionScreen({super.key});

  @override
  State<MemberContributionScreen> createState() => _MemberContributionScreenState();
}

class _MemberContributionScreenState extends State<MemberContributionScreen> {
  final AuthService _authService = AuthService();
  final Color themeColor = AppTheme.themeColor;

  final TextEditingController amountController = TextEditingController();
  final TextEditingController transactionRefController = TextEditingController();
  final TextEditingController numberOfMonthsController = TextEditingController(text: '1');

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  File? proofOfPayment;

  Future<void> pickProofOfPayment() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => proofOfPayment = File(pickedFile.path));
    }
  }

  Future<void> submitContribution() async {
    if (amountController.text.isEmpty ||
        transactionRefController.text.isEmpty ||
        proofOfPayment == null ||
        numberOfMonthsController.text.isEmpty) {
      await AppDialog.showWarningDialog(
        context,
        title: 'Incomplete Form',
        message: 'Please fill all fields and attach proof of payment.',
      );
      return;
    }

    AppDialog.showLoadingDialog(context);

    final profile = await _authService.getMemberProfile();
    final success = await _authService.addContribution({
      'member': profile?['id'],
      'amount': amountController.text,
      'payment_method': 'transfer',
      'transaction_ref': transactionRefController.text,
      'month': selectedMonth,
      'year': selectedYear,
      'number_of_months': numberOfMonthsController.text,
    }, proofOfPayment: proofOfPayment);

    Navigator.pop(context);

    if (success) {
      await AppDialog.showSuccessDialog(
        context,
        title: 'Contribution Submitted',
        message: 'Your contribution has been submitted successfully.',
      );
      Navigator.pop(context, true);
    } else {
      await AppDialog.showWarningDialog(
        context,
        title: 'Submission Failed',
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  void _showHelpModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 20),
            Text('Contribution Instructions', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                style: GoogleFonts.montserrat(height: 1.5),
                children: [
                  const TextSpan(text: '• This form is ONLY for transfers. For '),
                  TextSpan(text: 'cash payments', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: ', kindly hand over to the admin who will record it for you.\n\n'),
                  const TextSpan(text: '• Ensure you have transferred the amount to:\n\n'),
                  TextSpan(text: 'Account Name: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: 'Opened Heavens Chapel\n'),
                  TextSpan(text: 'Sort Code: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: '30-94-44\n'),
                  TextSpan(text: 'Account Number: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: '51659968\n\n'),
                  const TextSpan(text: '• Fill this form with your transaction details and upload proof of payment.'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: Text('Submit Contribution', style: GoogleFonts.montserrat(color: themeColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: themeColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildTextField('Amount (£)', amountController, TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField('Transaction Ref', transactionRefController),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildMonthDropdown()),
                const SizedBox(width: 12),
                Expanded(child: _buildYearDropdown()),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField('Number of Months', numberOfMonthsController, TextInputType.number),
            const SizedBox(height: 16),
            _buildProofOfPaymentPicker(),
            const SizedBox(height: 24),
            _buildInfoBox(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: submitContribution,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Submit', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, [TextInputType? inputType]) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      style: GoogleFonts.montserrat(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildMonthDropdown() {
    return DropdownButtonFormField<int>(
      value: selectedMonth,
      items: List.generate(12, (index) => DropdownMenuItem(value: index + 1, child: Text(monthName(index + 1)))),
      onChanged: (value) => setState(() => selectedMonth = value!),
      decoration: InputDecoration(
        labelText: 'Month',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildYearDropdown() {
    int currentYear = DateTime.now().year;
    return DropdownButtonFormField<int>(
      value: selectedYear,
      items: List.generate(5, (index) => DropdownMenuItem(value: currentYear - index, child: Text((currentYear - index).toString()))),
      onChanged: (value) => setState(() => selectedYear = value!),
      decoration: InputDecoration(
        labelText: 'Year',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildProofOfPaymentPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Proof of Payment (required)', style: GoogleFonts.montserrat(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton(
              onPressed: pickProofOfPayment,
              style: ElevatedButton.styleFrom(backgroundColor: themeColor),
              child: Text('Select Image', style: GoogleFonts.montserrat(color: Colors.white)),
            ),
            const SizedBox(width: 12),
            if (proofOfPayment != null) Text('Image selected', style: GoogleFonts.montserrat(color: Colors.green)),
          ],
        )
      ],
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeColor.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: themeColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transfer Only', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  'This form is for transfers ONLY. For cash payments, please hand over to the admin directly. Need help?',
                  style: GoogleFonts.montserrat(fontSize: 13),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _showHelpModal,
                  child: Text('See instructions', style: GoogleFonts.montserrat(color: themeColor, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

String monthName(int month) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return months[month - 1];
}
