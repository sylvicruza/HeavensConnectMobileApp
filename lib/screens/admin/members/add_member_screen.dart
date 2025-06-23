import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/auth_service.dart';
import '../../../utils/app_dialog.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/setting_keys.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  Map<String, List<String>> systemSettings = {};
  List<String> statusOptions = [];
  bool settingsLoading = true;


  String status = 'active';
  File? _profileImage;

  final Color themeColor = Colors.deepPurple;

  @override
  void initState() {
    super.initState();
    _loadSystemSettings();
  }

  Future<void> _loadSystemSettings() async {
    final settings = await AuthService().getSystemSettings();  // already flat map

    setState(() {
      systemSettings = Map<String, List<String>>.from(settings);
      statusOptions = systemSettings[SettingKeys.memberStatuses] ?? ['active', 'inactive', 'deceased'];
      settingsLoading = false;
    });
  }




  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    AppDialog.showLoadingDialog(context, message: 'Submitting member data...');

    final data = {
      'full_name': _fullNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'status': 'active',
    };

    final success = await AuthService().addMemberWithImage(data, _profileImage);

    Navigator.pop(context); // Close loading

    if (success) {
      await AppDialog.showSuccessDialog(
        context,
        title: 'Member Added!',
        message: 'The member was successfully added to the system.',
      );
      Navigator.pop(context, true);
    } else {
      await AppDialog.showWarningDialog(
        context,
        title: 'Error',
        message: 'Failed to add member. Please try again.',
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor,
        elevation: 1,
        iconTheme: IconThemeData(color: themeColor),
        title: Text('Add Member', style: montserratTextStyle(color: themeColor)),
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
              _buildCardField(_buildTextField(_phoneController, 'Phone Number', keyboardType: TextInputType.phone, required: true)),
              _buildCardField(_buildTextField(_addressController, 'Address')),
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

  Widget _buildDropdownField() {
    if (settingsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DropdownButtonFormField<String>(
      value: statusOptions.contains(status) ? status : statusOptions.first,
      items: statusOptions
          .map((option) => DropdownMenuItem(
        value: option,
        child: Text(option.isNotEmpty ? '${option[0].toUpperCase()}${option.substring(1)}' : ''),
      ))
          .toList(),

      onChanged: (value) => setState(() => status = value!),
      decoration: InputDecoration(
        labelText: 'Status',
        border: InputBorder.none,
        labelStyle: montserratTextStyle(),
      ),
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
      onPressed: _submitForm,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        backgroundColor: themeColor,
      ),
      child: Text('Submit', style: montserratTextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }


}
