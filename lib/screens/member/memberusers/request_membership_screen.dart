import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_dialog.dart';
import '../../../utils/app_theme.dart';

class RequestMembershipScreen extends StatefulWidget {
  const RequestMembershipScreen({super.key});

  @override
  State<RequestMembershipScreen> createState() => _RequestMembershipScreenState();
}

class _RequestMembershipScreenState extends State<RequestMembershipScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  File? _profileImage;

  final Color themeColor = AppTheme.themeColor;

  bool isEmailVerified = false;
  bool codeSent = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  Future<void> _sendVerificationCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      AppDialog.showWarningDialog(context, title: 'Email Required', message: 'Please enter your email.');
      return;
    }

    AppDialog.showLoadingDialog(context);
    final success = await _authService.sendVerificationCode(email);
    Navigator.pop(context);

    if (success) {
      setState(() => codeSent = true);
      AppDialog.showSuccessDialog(
        context,
        title: 'Code Sent',
        message: 'A verification code has been sent to $email. Please enter it below.',
      );
    } else {
      AppDialog.showWarningDialog(context, title: 'Failed', message: 'This email is already registered. Try another.');
    }
  }

  Future<void> _verifyCode() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      AppDialog.showWarningDialog(context, title: 'Code Required', message: 'Please enter the verification code.');
      return;
    }

    AppDialog.showLoadingDialog(context);
    final success = await _authService.verifyEmailCode(email, code);
    Navigator.pop(context);

    if (success) {
      setState(() => isEmailVerified = true);
      AppDialog.showSuccessDialog(
        context,
        title: 'Email Verified',
        message: 'You can now submit your request.',
      );
    } else {
      AppDialog.showWarningDialog(context, title: 'Invalid Code', message: 'The code you entered is invalid.');
    }
  }

  void _submitRequest() async {
    if (!isEmailVerified) {
      AppDialog.showWarningDialog(context, title: 'Email Not Verified', message: 'Please verify your email first.');
      return;
    }

    if (_formKey.currentState!.validate()) {
      AppDialog.showLoadingDialog(context);

      final success = await _authService.requestMembership(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        email: _emailController.text.trim(),
        profilePicture: _profileImage,
      );

      Navigator.pop(context); // Close loading

      if (success) {
        await AppDialog.showSuccessDialog(
          context,
          title: 'Request Submitted!',
          message: 'Your membership request has been submitted for approval.',
        );
        Navigator.pop(context);
      } else {
        await AppDialog.showWarningDialog(
          context,
          title: 'Request Failed',
          message: 'Failed to submit request. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor,
        elevation: 1,
        iconTheme: IconThemeData(color: themeColor),
        title: Text('Request Membership', style: montserratTextStyle(color: themeColor)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildProfileImagePicker(),
              const SizedBox(height: 20),
              _buildCardField(_buildTextField(_fullNameController, 'Full Name', required: true)),
              _buildCardField(_buildTextField(_emailController, 'Email', keyboardType: TextInputType.emailAddress, required: true)),
              _buildVerifyEmailSection(),
              _buildCardField(_buildTextField(_phoneController, 'Phone Number', keyboardType: TextInputType.phone, required: true)),
              _buildCardField(_buildTextField(_addressController, 'Address', required: true)),
              const SizedBox(height: 30),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardField(Widget child) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: child,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool required = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: InputBorder.none,
        labelStyle: montserratTextStyle(),
      ),
      validator: required ? (value) => value == null || value.isEmpty ? 'Required' : null : null,
    );
  }

  Widget _buildVerifyEmailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!codeSent)
          ElevatedButton(
            onPressed: _sendVerificationCode,
            child: Text('Send Verification Code'),
          ),
        if (codeSent && !isEmailVerified)
          Column(
            children: [
              _buildCardField(_buildTextField(_codeController, 'Enter Verification Code')),
              ElevatedButton(
                onPressed: _verifyCode,
                child: Text('Verify Code'),
              ),
            ],
          ),
        if (isEmailVerified)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('✅ Email Verified', style: montserratTextStyle(color: Colors.green)),
          ),
      ],
    );
  }

  Widget _buildProfileImagePicker() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: themeColor.withOpacity(0.1),
          backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
          child: _profileImage == null
              ? Icon(Icons.person, size: 50, color: themeColor)
              : null,
        ),
        FloatingActionButton(
          mini: true,
          backgroundColor: themeColor,
          onPressed: _pickImage,
          child: const Icon(Icons.add_a_photo, size: 18, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submitRequest,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        backgroundColor: themeColor,
      ),
      child: Text('Submit Request', style: montserratTextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}
