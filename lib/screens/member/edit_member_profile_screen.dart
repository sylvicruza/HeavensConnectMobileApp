import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../utils/app_dialog.dart';
import '../../utils/app_theme.dart';

class EditMemberProfileScreen extends StatefulWidget {
  final Map<String, dynamic> memberData;

  const EditMemberProfileScreen({super.key, required this.memberData});

  @override
  State<EditMemberProfileScreen> createState() => _EditMemberProfileScreenState();
}

class _EditMemberProfileScreenState extends State<EditMemberProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final Color themeColor = AppTheme.themeColor;

  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.memberData['full_name']);
    _phoneController = TextEditingController(text: widget.memberData['phone_number']);
    _emailController = TextEditingController(text: widget.memberData['email'] ?? '');
    _addressController = TextEditingController(text: widget.memberData['address'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: themeColor),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: themeColor),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _formSectionTitle('Personal Information'),
              const SizedBox(height: 10),
              _buildTextField(_fullNameController, 'Full Name'),
              _buildTextField(_phoneController, 'Phone Number', keyboardType: TextInputType.phone),
              _buildTextField(_emailController, 'Email', keyboardType: TextInputType.emailAddress),
              _buildTextField(_addressController, 'Address', maxLines: 2),
              const SizedBox(height: 30),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(colors: [themeColor, themeColor]),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: isSubmitting ? null : _saveChanges,
                    child: Center(
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                        'Save Changes',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _formSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.montserrat(),
          decoration: InputDecoration(
            labelText: label,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    final success = await _authService.updateMemberProfile({
      'full_name': _fullNameController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'address': _addressController.text.trim(),
    });

    setState(() => isSubmitting = false);

    if (success) {
      await AppDialog.showSuccessDialog(
        context,
        title: 'Profile Updated',
        message: 'Your profile has been updated successfully.',
      );
      Navigator.pop(context, true);
    } else {
      await AppDialog.showWarningDialog(
        context,
        title: 'Failed',
        message: 'Failed to update profile. Please try again.',
      );
    }
  }
}
