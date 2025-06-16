import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../utils/app_dialog.dart';
import '../../utils/app_theme.dart';

class EditAdminUserScreen extends StatefulWidget {
  final dynamic adminData;

  const EditAdminUserScreen({super.key, required this.adminData});

  @override
  State<EditAdminUserScreen> createState() => _EditAdminUserScreenState();
}

class _EditAdminUserScreenState extends State<EditAdminUserScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final Color themeColor = AppTheme.themeColor;

  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String _selectedRole = 'admin';
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    final data = widget.adminData;
    _fullNameController = TextEditingController(text: data['full_name']);
    _emailController = TextEditingController(text: data['email'] ?? '');
    _phoneController = TextEditingController(text: data['phone_number']);
    _selectedRole = data['role'];
  }

  void _submitEdit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isProcessing = true);

    final success = await _authService.editAdminUser(
      widget.adminData['id'],
      {
        'full_name': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'role': _selectedRole,
      },
    );

    setState(() => isProcessing = false);

    if (success) {
      await AppDialog.showSuccessDialog(
        context,
        title: 'Updated',
        message: 'Admin user updated successfully.',
      );
      Navigator.pop(context, true);
    } else {
      await AppDialog.showWarningDialog(
        context,
        title: 'Failed',
        message: 'Failed to update admin user. Please try again.',
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
        title: Text('Edit Admin User',
            style: montserratTextStyle(color: themeColor, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildCardField(_buildTextField(
                  controller: _fullNameController, label: 'Full Name')),
              _buildCardField(_buildTextField(
                  controller: _emailController, label: 'Email', keyboard: TextInputType.emailAddress)),
              _buildCardField(_buildTextField(
                  controller: _phoneController, label: 'Phone Number', keyboard: TextInputType.phone)),
              _buildCardField(_buildRoleDropdown()),
              const SizedBox(height: 30),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// ------- Form Field with Card style -------
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

  /// ------- TextField Builder -------
  Widget _buildTextField(
      {required TextEditingController controller,
        required String label,
        TextInputType keyboard = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: InputBorder.none,
        labelStyle: montserratTextStyle(),
      ),
      validator: (value) =>
      value == null || value.isEmpty ? 'Required' : null,
    );
  }

  /// ------- Role Dropdown -------
  Widget _buildRoleDropdown() {
    return DropdownButtonFormField(
      value: _selectedRole,
      items: ['admin', 'finance']
          .map((role) => DropdownMenuItem(
          value: role,
          child: Text(role.toUpperCase(),
              style: montserratTextStyle())))
          .toList(),
      onChanged: (value) {
        if (value != null) setState(() => _selectedRole = value);
      },
      decoration: const InputDecoration(border: InputBorder.none, labelText: 'Role'),
      validator: (value) => value == null ? 'Select a role' : null,
    );
  }

  /// ------- Submit Button -------
  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: isProcessing ? null : _submitEdit,
      style: ElevatedButton.styleFrom(
        backgroundColor: themeColor,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isProcessing
          ? const CircularProgressIndicator(color: Colors.white)
          : Text('Save Changes',
          style: montserratTextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}
