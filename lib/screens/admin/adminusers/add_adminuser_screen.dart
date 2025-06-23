import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heavens_connect/services/auth_service.dart';
import 'package:heavens_connect/utils/setting_keys.dart';
import '../../../utils/app_dialog.dart';
import '../../../utils/app_theme.dart';

class AdminCreateUserScreen extends StatefulWidget {
  const AdminCreateUserScreen({super.key});

  @override
  State<AdminCreateUserScreen> createState() => _AdminCreateUserScreenState();
}

class _AdminCreateUserScreenState extends State<AdminCreateUserScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String role = 'admin';
  List<String> availableRoles = [];
  bool settingsLoading = true;
  bool isProcessing = false;

  final Color themeColor = AppTheme.themeColor;

  @override
  void initState() {
    super.initState();
    _loadSystemSettings();
  }

  Future<void> _loadSystemSettings() async {
    final settings = await _authService.getSystemSettings();
    final roles = settings[SettingKeys.adminRoles] ?? ['admin', 'finance'];

    setState(() {
      availableRoles = roles;
      role = roles.first;
      settingsLoading = false;
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isProcessing = true);
    AppDialog.showLoadingDialog(context);

    final success = await _authService.createAdminUser(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      role: role,
    );

    Navigator.pop(context); // Close loading
    setState(() => isProcessing = false);

    if (success) {
      await AppDialog.showSuccessDialog(
        context,
        title: 'Success',
        message: 'Admin user created successfully.',
      );
      Navigator.pop(context, true);
    } else {
      await AppDialog.showWarningDialog(
        context,
        title: 'Failed',
        message: 'Could not create admin user. Try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor,
        elevation: 1,
        iconTheme: IconThemeData(color: themeColor),
        title: Text('Create Admin User',
            style: montserratTextStyle(color: themeColor, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildCardField(
                _buildTextField(_fullNameController, 'Full Name', required: true),
              ),
              _buildCardField(
                _buildTextField(_emailController, 'Email',
                    required: true, keyboardType: TextInputType.emailAddress),
              ),
              _buildCardField(
                _buildTextField(_phoneController, 'Phone Number',
                    required: true, keyboardType: TextInputType.phone),
              ),
              _buildCardField(_buildRoleDropdown()),
              const SizedBox(height: 30),
              _buildSubmitButton()
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardField(Widget child) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: child,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool required = false, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: InputBorder.none,
        labelStyle: montserratTextStyle(),
      ),
      validator: required
          ? (val) => val == null || val.isEmpty ? 'Required' : null
          : null,
    );
  }

  Widget _buildRoleDropdown() {
    if (settingsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DropdownButtonFormField<String>(
      value: availableRoles.contains(role) ? role : availableRoles.first,
      items: availableRoles
          .map((r) => DropdownMenuItem(
        value: r,
        child: Text(
          r[0].toUpperCase() + r.substring(1),
          style: montserratTextStyle(),
        ),
      ))
          .toList(),
      decoration: const InputDecoration(
          labelText: 'Role', border: InputBorder.none),
      onChanged: (value) {
        if (value != null) setState(() => role = value);
      },
      validator: (value) => value == null ? 'Please select a role' : null,
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: isProcessing ? null : _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: themeColor,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isProcessing
          ? const CircularProgressIndicator(color: Colors.white)
          : Text('Create User',
          style: montserratTextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}
