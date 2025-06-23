import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heavens_connect/services/auth_service.dart';
import 'package:heavens_connect/services/contribution_service.dart';
import 'package:heavens_connect/utils/setting_keys.dart';
import 'package:image_picker/image_picker.dart';
import 'package:heavens_connect/utils/app_dialog.dart';
import '../../../utils/app_theme.dart';

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
  String? bankDetails;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _authService.getSystemSettings();
    setState(() {
      bankDetails = settings[SettingKeys.bankAccount]?.join('\n') ?? '';
    });
  }

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
      final amount = amountController.text;
      final numMonths = int.tryParse(numberOfMonthsController.text) ?? 1;
      final customMessage = numMonths > 1
          ? "You submitted a contribution of \u00a3$amount split across $numMonths months.\n\nYour contribution is pending verification and will reflect on your balance once approved."
          : "You submitted a contribution of \u00a3$amount.\n\nYour contribution is pending verification and will reflect on your balance once approved.";

      await AppDialog.showSuccessDialog(
        context,
        title: 'Contribution Submitted',
        message: customMessage,
      );

      Navigator.pushReplacementNamed(context, '/memberContributionList');
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 20),
            Text('Contribution Instructions', style: montserratTextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                style: montserratTextStyle(height: 1.5),
                children: [
                  const TextSpan(text: '\u2022 This form is ONLY for transfers. For '),
                  TextSpan(text: 'cash payments', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: ', kindly hand over to the admin who will record it for you.\n\n'),
                  const TextSpan(text: '\u2022 Ensure you have transferred the amount to:\n\n'),
                  TextSpan(text: bankDetails ?? 'Bank account not found\n', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: '\n\u2022 Fill this form with your transaction details and upload proof of payment.'),
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
      resizeToAvoidBottomInset: true,
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: Text('Submit Contribution', style: montserratTextStyle(color: themeColor, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.appBarColor,
        elevation: 0,
        iconTheme: IconThemeData(color: themeColor),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBorderedTextField('Amount (£)', amountController, TextInputType.number),
                    const SizedBox(height: 16),
                    _buildBorderedTextField('Transaction Ref', transactionRefController),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildBorderedDropdown('Month', selectedMonth, 12, monthName, (val) => setState(() => selectedMonth = val))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildBorderedDropdown('Year', selectedYear, 3, (val) => val.toString(), (val) => setState(() => selectedYear = val))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildBorderedTextField('Number of Months', numberOfMonthsController, TextInputType.number),
                    const SizedBox(height: 20),
                    _buildProofOfPaymentPicker(),
                    const SizedBox(height: 24),
                    _buildInfoBox(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: _showConfirmationDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                ),
                child: Text('Submit Contribution', style: montserratTextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBorderedTextField(String label, TextEditingController controller, [TextInputType? inputType]) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      style: montserratTextStyle(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: montserratTextStyle(color: themeColor),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildBorderedDropdown(String label, int currentValue, int count, String Function(int) labelBuilder, Function(int) onChanged) {
    return DropdownButtonFormField<int>(
      value: currentValue,
      onChanged: (val) => onChanged(val!),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: montserratTextStyle(color: themeColor),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: List.generate(count, (i) {
        int value = label == 'Year' ? currentValue - i : i + 1;
        return DropdownMenuItem(value: value, child: Text(labelBuilder(value)));
      }),
    );
  }

  Widget _buildProofOfPaymentPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Proof of Payment (required)', style: montserratTextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: [
            ElevatedButton(
              onPressed: pickProofOfPayment,
              style: ElevatedButton.styleFrom(backgroundColor: themeColor),
              child: Text('Upload Image', style: montserratTextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 12),
            if (proofOfPayment != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(proofOfPayment!, width: 60, height: 60, fit: BoxFit.cover),
              ),
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
                Text('Transfer Only', style: montserratTextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  'This form is for transfers ONLY. For cash payments, please hand over to the admin directly. Need help?',
                  style: montserratTextStyle(fontSize: 13),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _showHelpModal,
                  child: Text('See instructions', style: montserratTextStyle(color: themeColor, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _showConfirmationDialog() async {
    final amount = amountController.text.trim();
    final transactionRef = transactionRefController.text.trim();
    final months = numberOfMonthsController.text.trim();
    final monthNameStr = monthName(selectedMonth);
    final yearStr = selectedYear.toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm Contribution', style: montserratTextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfirmationRow('Amount', '£$amount'),
            _buildConfirmationRow('Months', months),
            _buildConfirmationRow('Month/Year', '$monthNameStr $yearStr'),
            _buildConfirmationRow('Transaction Ref', transactionRef),
            _buildConfirmationRow('Proof Attached', proofOfPayment != null ? 'Yes' : 'No'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: montserratTextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: themeColor),
            child: Text('Confirm', style: montserratTextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await submitContribution();
    }
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: montserratTextStyle(fontWeight: FontWeight.w500))),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: Text(value, style: montserratTextStyle())),
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

