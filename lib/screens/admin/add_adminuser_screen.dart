import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heavens_connect/services/auth_service.dart';
import '../../utils/app_dialog.dart';
import '../../utils/app_theme.dart';

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

  final Color themeColor = AppTheme.themeColor;
  bool isProcessing = false;

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
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: themeColor),
        title: Text('Create Admin User',
            style: GoogleFonts.montserrat(
                color: themeColor, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildCardField(
                  _buildTextField(_fullNameController, 'Full Name', required: true)),
              _buildCardField(
                  _buildTextField(_emailController, 'Email', required: true, keyboardType: TextInputType.emailAddress)),
              _buildCardField(
                  _buildTextField(_phoneController, 'Phone Number', required: true, keyboardType: TextInputType.phone)),
              _buildCardField(_buildRoleDropdown()),
              const SizedBox(height: 30),
              _buildSubmitButton()
            ],
          ),
        ),
      ),
    );
  }

  // ---- BEAUTIFUL FIELD WRAPPER ----
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

  // ---- TEXT FIELD ----
  Widget _buildTextField(TextEditingController controller, String label,
      {bool required = false,
        TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: InputBorder.none,
        labelStyle: GoogleFonts.montserrat(),
      ),
      validator: required
          ? (val) => val == null || val.isEmpty ? 'Required' : null
          : null,
    );
  }

  // ---- DROPDOWN ----
  Widget _buildRoleDropdown() {
    return DropdownButtonFormField(
      value: role,
      items: ['admin', 'finance']
          .map((r) => DropdownMenuItem(
          value: r,
          child: Text(r[0].toUpperCase() + r.substring(1),
              style: GoogleFonts.montserrat())))
          .toList(),
      decoration: const InputDecoration(
          labelText: 'Role', border: InputBorder.none),
      onChanged: (value) {
        if (value != null) setState(() => role = value);
      },
      validator: (value) => value == null ? 'Please select a role' : null,
    );
  }

  // ---- BUTTON ----
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
          style: GoogleFonts.montserrat(
              color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}
