import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heavens_connect/services/contribution_service.dart';
import 'package:heavens_connect/utils/setting_keys.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../services/auth_service.dart';
import '../../utils/app_dialog.dart';
import '../../utils/app_theme.dart';

class AddContributionScreen extends StatefulWidget {
  const AddContributionScreen({super.key});

  @override
  State<AddContributionScreen> createState() => _AddContributionScreenState();
}

class _AddContributionScreenState extends State<AddContributionScreen> {
  final AuthService _authService = AuthService();

  int? selectedMemberId;
  List<Map<String, dynamic>> members = [];

  final TextEditingController amountController = TextEditingController();
  final TextEditingController transactionRefController = TextEditingController();
  final TextEditingController numberOfMonthsController = TextEditingController(text: '1');

  String paymentMethod = 'cash';
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  File? proofOfPayment;
  final Color themeColor = AppTheme.themeColor;

  Map<String, List<String>> systemSettings = {};
  List<String> paymentMethods = [];
  bool settingsLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMembers();
    _loadSystemSettings();
  }

  Future<void> _loadSystemSettings() async {
    final settings = await _authService.getSystemSettings();
    final methods = settings[SettingKeys.paymentMethods] ?? ['cash', 'transfer'];

    setState(() {
      systemSettings = settings;
      paymentMethods = methods;
      if (!paymentMethods.contains(paymentMethod)) {
        paymentMethod = paymentMethods.first;
      }
      settingsLoading = false;
    });
  }

  Future<void> fetchMembers() async {
    final data = await _authService.getAllMembers();
    if (data != null) {
      setState(() => members = data.cast<Map<String, dynamic>>());
    }
  }

  Future<void> pickProofOfPayment() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => proofOfPayment = File(pickedFile.path));
  }

  Future<void> submitContribution() async {
    if (selectedMemberId == null || amountController.text.isEmpty || numberOfMonthsController.text.isEmpty) {
      return AppDialog.showWarningDialog(context, title: 'Missing Fields', message: 'Please fill all required fields.');
    }

    if (paymentMethod == 'transfer') {
      if (transactionRefController.text.isEmpty) {
        return AppDialog.showWarningDialog(context, title: 'Missing Reference', message: 'Transaction reference is required.');
      }
      if (proofOfPayment == null) {
        return AppDialog.showWarningDialog(context, title: 'Missing Proof', message: 'Proof of payment is required.');
      }
    }

    AppDialog.showLoadingDialog(context);

    final success = await _authService.addContribution({
      'member': selectedMemberId,
      'amount': amountController.text,
      'payment_method': paymentMethod,
      'month': selectedMonth,
      'year': selectedYear,
      'transaction_ref': paymentMethod == 'transfer' ? transactionRefController.text : null,
      'number_of_months': numberOfMonthsController.text,
    }, proofOfPayment: proofOfPayment);

    Navigator.pop(context); // Close loading

    if (success) {
      await AppDialog.showSuccessDialog(context, title: 'Contribution Successful', message: 'The contribution was added successfully.');
      Navigator.pop(context, true);
    } else {
      await AppDialog.showWarningDialog(context, title: 'Failed', message: 'Failed to add contribution.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: Text('Add Contribution',
            style: montserratTextStyle(color: themeColor, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.appBarColor,
        iconTheme: IconThemeData(color: themeColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Member'),
          _card(_buildMemberDropdown()),

          const SizedBox(height: 16),
          _sectionTitle('Amount'),
          _card(_buildAmountField()),

          const SizedBox(height: 16),
          _sectionTitle('Payment Method'),
          _card(_buildPaymentMethodDropdown()),

          if (paymentMethod == 'transfer') ...[
            const SizedBox(height: 16),
            _sectionTitle('Transaction Reference'),
            _card(_buildTextField('Transaction Ref', transactionRefController)),

            const SizedBox(height: 16),
            _sectionTitle('Proof of Payment'),
            _card(_buildProofOfPaymentPicker()),
          ],

          const SizedBox(height: 16),
          _sectionTitle('Number of Months'),
          _card(_buildTextField('Number of Months', numberOfMonthsController, TextInputType.number)),

          const SizedBox(height: 16),
          _sectionTitle('Contribution Period'),
          _card(Row(
            children: [
              Expanded(child: _buildMonthDropdown()),
              const SizedBox(width: 12),
              Expanded(child: _buildYearDropdown()),
            ],
          )),

          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: submitContribution,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Submit Contribution',
                style: montserratTextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 6)],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: montserratTextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[800]));
  }

  Widget _buildMemberDropdown() {
    return DropdownSearch<Map<String, dynamic>>(
      asyncItems: (filter) async => (await _authService.searchMembers(filter))?.cast<Map<String, dynamic>>() ?? [],
      itemAsString: (member) => member['full_name'],
      onChanged: (value) => setState(() => selectedMemberId = value?['id']),
      selectedItem: selectedMemberId != null
          ? {'id': selectedMemberId, 'full_name': _getMemberName(selectedMemberId!)}
          : null,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
            border: InputBorder.none, hintText: 'Select Member'),
      ),
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
            decoration:
            const InputDecoration(hintText: 'Search member...')),
      ),
    );
  }

  String _getMemberName(int id) {
    final member = members.firstWhere((m) => m['id'] == id, orElse: () => {});
    return member.isNotEmpty ? member['full_name'] : 'Selected Member';
  }

  Widget _buildAmountField() {
    return TextField(
      controller: amountController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        prefixText: '£ ',
        border: InputBorder.none,
        hintText: 'Enter Amount',
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, [TextInputType? inputType]) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(border: InputBorder.none, hintText: hint),
    );
  }

  Widget _buildPaymentMethodDropdown() {
    if (settingsLoading) return const Center(child: CircularProgressIndicator());

    return DropdownButtonFormField<String>(
      value: paymentMethod,
      items: paymentMethods
          .map((method) => DropdownMenuItem(
        value: method,
        child: Row(
          children: [
            Icon(method == 'cash' ? Icons.attach_money : Icons.swap_horiz),
            const SizedBox(width: 8),
            Text(method.capitalize()),
          ],
        ),
      ))
          .toList(),
      onChanged: (value) => setState(() => paymentMethod = value!),
      decoration: const InputDecoration(border: InputBorder.none),
    );
  }

  Widget _buildMonthDropdown() {
    return DropdownButtonFormField<int>(
      value: selectedMonth,
      items: List.generate(12, (index) =>
          DropdownMenuItem(value: index + 1, child: FittedBox(child: Text(monthName(index + 1))))),
      onChanged: (value) => setState(() => selectedMonth = value!),
      decoration: const InputDecoration(border: InputBorder.none),
    );
  }

  Widget _buildYearDropdown() {
    final currentYear = DateTime.now().year;
    return DropdownButtonFormField<int>(
      value: selectedYear,
      items: List.generate(5, (index) =>
          DropdownMenuItem(value: currentYear - index, child: Text('${currentYear - index}'))),
      onChanged: (value) => setState(() => selectedYear = value!),
      decoration: const InputDecoration(border: InputBorder.none),
    );
  }

  Widget _buildProofOfPaymentPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: pickProofOfPayment,
          style: ElevatedButton.styleFrom(backgroundColor: themeColor),
          child: const Text('Select Image', style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 8),
        if (proofOfPayment != null)
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  proofOfPayment!.path.split('/').last,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() => isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
}

String monthName(int month) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return months[month - 1];
}
