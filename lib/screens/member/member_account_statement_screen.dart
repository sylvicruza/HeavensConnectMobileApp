import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../utils/app_dialog.dart';
import '../../utils/app_theme.dart';

class MemberAccountStatementScreen extends StatefulWidget {
  const MemberAccountStatementScreen({super.key});

  @override
  State<MemberAccountStatementScreen> createState() =>
      _MemberAccountStatementScreenState();
}

class _MemberAccountStatementScreenState
    extends State<MemberAccountStatementScreen> {
  final Color themeColor = AppTheme.themeColor;
  final AuthService _authService = AuthService();

  DateTime? _fromDate;
  DateTime? _toDate;
  final DateFormat _displayFormat = DateFormat('dd MMM yyyy');

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: themeColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_fromDate == null || _toDate == null) {
      AppDialog.showWarningDialog(
        context,
        title: 'Dates Required',
        message: 'Please select a date range.',
      );
      return;
    }

    AppDialog.showLoadingDialog(context);

    final response = await _authService.requestAccountStatement(
      fromDate: _fromDate!,
      toDate: _toDate!,
      format: 'pdf',
    );

    Navigator.pop(context);

    if (response == "success") {
      AppDialog.showSuccessDialog(
        context,
        title: 'Statement Sent',
        message: 'Your account statement has been emailed to you.',
      );
    } else {
      AppDialog.showWarningDialog(
        context,
        title: 'Failed',
        message: response,
      );
    }
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
          'Request Statement',
          style: GoogleFonts.montserrat(
            color: themeColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Date Range',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickDateRange,
              child: Container(
                padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 8,
                        offset: const Offset(0, 4)),
                  ],
                  border: Border.all(color: themeColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, color: themeColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _fromDate != null && _toDate != null
                            ? '${_displayFormat.format(_fromDate!)} → ${_displayFormat.format(_toDate!)}'
                            : 'Tap to select date range',
                        style: GoogleFonts.montserrat(
                            fontSize: 15, color: Colors.grey[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text('Format',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              width: double.infinity,
              decoration: BoxDecoration(
                color: themeColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Center(
                child: Text(
                  'PDF',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const Spacer(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient:
                LinearGradient(colors: [themeColor, themeColor.withOpacity(0.8)]),
                boxShadow: [
                  BoxShadow(
                      color: themeColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5)),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _submitRequest,
                  child: Center(
                    child: Text(
                      'Request Statement',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
