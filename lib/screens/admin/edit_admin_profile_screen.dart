import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../utils/app_dialog.dart';
import '../../utils/app_theme.dart';

class EditAdminProfileScreen extends StatefulWidget {
  final Map<String, dynamic> adminData;
  const EditAdminProfileScreen({super.key, required this.adminData});

  @override
  State<EditAdminProfileScreen> createState() => _EditAdminProfileScreenState();
}

class _EditAdminProfileScreenState extends State<EditAdminProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final Color themeColor = AppTheme.themeColor;

  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fullNameController =
        TextEditingController(text: widget.adminData['full_name']);
    _emailController =
        TextEditingController(text: widget.adminData['email'] ?? '');
    _phoneController =
        TextEditingController(text: widget.adminData['phone_number']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: themeColor),
        title: Text('Edit Profile',
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
                  _buildTextField(_fullNameController, 'Full Name', true)),
              _buildCardField(
                  _buildTextField(_emailController, 'Email', true, keyboardType: TextInputType.emailAddress)),
              _buildCardField(
                  _buildTextField(_phoneController, 'Phone Number', true, keyboardType: TextInputType.phone)),
              const SizedBox(height: 30),
              _buildSaveButton()
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
      bool required,
      {TextInputType keyboardType = TextInputType.text}) {
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

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: isProcessing ? null : _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: themeColor,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isProcessing
          ? const CircularProgressIndicator(color: Colors.white)
          : Text('Save Changes',
          style: GoogleFonts.montserrat(
              color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isProcessing = true);

    final updatedData = {
      'full_name': _fullNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone_number': _phoneController.text.trim(),
    };

    final success = await _authService.updateAdminProfile(updatedData);

    setState(() => isProcessing = false);

    if (success) {
      await AppDialog.showSuccessDialog(
        context,
        title: 'Updated',
        message: 'Profile updated successfully.',
      );
      Navigator.pop(context, true);
    } else {
      await AppDialog.showWarningDialog(
        context,
        title: 'Failed',
        message: 'Could not update profile.',
      );
    }
  }
}
