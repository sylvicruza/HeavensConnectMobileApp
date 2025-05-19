import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../utils/app_dialog.dart';
import '../../utils/setting_keys.dart';

class EditMemberScreen extends StatefulWidget {
  final Map<String, dynamic> member;

  const EditMemberScreen({super.key, required this.member});

  @override
  State<EditMemberScreen> createState() => _EditMemberScreenState();
}

class _EditMemberScreenState extends State<EditMemberScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  String? _status;
  List<String> statusOptions = [];
  bool settingsLoading = true;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.member['full_name']);
    _emailController = TextEditingController(text: widget.member['email']);
    _phoneController = TextEditingController(text: widget.member['phone_number']);
    _addressController = TextEditingController(text: widget.member['address']);
    _status = widget.member['status'];
    _loadSystemSettings();
  }

  Future<void> _loadSystemSettings() async {
    final settings = await _authService.getSystemSettings();
    setState(() {
      statusOptions = settings[SettingKeys.memberStatuses] ?? ['active', 'inactive'];
      settingsLoading = false;
    });
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      AppDialog.showLoadingDialog(context);

      final updatedMember = {
        'full_name': _fullNameController.text,
        'email': _emailController.text,
        'phone_number': _phoneController.text,
        'address': _addressController.text,
        'status': _status,
      };

      final success = await _authService.editMember(widget.member['id'], updatedMember);

      Navigator.pop(context); // Close loading

      if (success) {
        await AppDialog.showSuccessDialog(context, title: 'Member Updated');
        Navigator.pop(context, true);
      } else {
        await AppDialog.showWarningDialog(context, title: 'Failed to update member');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.deepPurple;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Member', style: GoogleFonts.montserrat()),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: themeColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildCardField(_buildTextField(_fullNameController, 'Full Name', true)),
              _buildCardField(_buildTextField(_emailController, 'Email', false)),
              _buildCardField(_buildTextField(_phoneController, 'Phone Number', true)),
              _buildCardField(_buildTextField(_addressController, 'Address', false)),
              _buildCardField(_buildStatusDropdown()),
              const SizedBox(height: 30),
              _buildSaveButton(themeColor),
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

  Widget _buildTextField(TextEditingController controller, String label, bool required) {
    return TextFormField(
      controller: controller,
      validator: (value) => required && (value == null || value.isEmpty) ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        border: InputBorder.none,
        labelStyle: GoogleFonts.montserrat(),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    if (settingsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DropdownButtonFormField<String>(
      value: statusOptions.contains(_status) ? _status : statusOptions.first,
      items: statusOptions
          .map((status) => DropdownMenuItem(
        value: status,
        child: Text(status.isNotEmpty ? '${status[0].toUpperCase()}${status.substring(1)}' : ''),
      ))
          .toList(),
      onChanged: (value) => setState(() => _status = value),
      decoration: InputDecoration(
        labelText: 'Status',
        border: InputBorder.none,
        labelStyle: GoogleFonts.montserrat(),
      ),
    );
  }

  Widget _buildSaveButton(Color themeColor) {
    return ElevatedButton(
      onPressed: _saveChanges,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        backgroundColor: themeColor,
      ),
      child: Text('Save Changes', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}
