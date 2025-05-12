import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/auth_service.dart';
import '../../utils/app_dialog.dart';
import '../../utils/app_theme.dart';

class AdminFinanceDashboardScreen extends StatefulWidget {
  const AdminFinanceDashboardScreen({super.key});

  @override
  State<AdminFinanceDashboardScreen> createState() => _AdminFinanceDashboardScreenState();
}

class _AdminFinanceDashboardScreenState extends State<AdminFinanceDashboardScreen> {
  final AuthService _authService = AuthService();
  final Color themeColor = AppTheme.themeColor;

  List<dynamic> transactions = [];
  Map<String, dynamic> summary = {};

  String filter = 'all'; // all | income | expense

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFinanceData();
  }

  Future<void> loadFinanceData() async {
    setState(() => isLoading = true);

    final s = await _authService.getFinanceSummary();
    final txns = await _authService.getFinanceTransactions();

    setState(() {
      summary = s ?? {};
      transactions = txns['transactions'] ?? [];
      isLoading = false;
    });
  }

  List<dynamic> get filteredTransactions {
    if (filter == 'income') return transactions.where((t) => t['type'] == 'income').toList();
    if (filter == 'expense') return transactions.where((t) => t['type'] == 'expense').toList();
    return transactions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Finance Overview', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: themeColor)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: themeColor),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: loadFinanceData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBalanceSummary(),
            const SizedBox(height: 20),
            _buildAnimatedBarChart(),
            const SizedBox(height: 20),
            //_buildDonutChart(),
            const SizedBox(height: 20),
            _buildFilterButtons(),
            const SizedBox(height: 12),
            ...filteredTransactions.map(_buildTransactionTile).toList(),
            const SizedBox(height: 20),
          /*  ElevatedButton.icon(
              onPressed: () {
                _openPrintDialog();  // Same function as the FAB "Print Statement"
              },
              icon: const Icon(Icons.download),
              label: const Text('Download Statement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                padding: const EdgeInsets.all(16),
              ),
            ),*/
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPrintDialog,
        backgroundColor: themeColor,
        icon: const Icon(Icons.print),
        label: const Text('Print Statement'),
      ),
    );
  }

  Widget _buildBalanceSummary() {
    double totalIncome = double.tryParse(summary['total_income']?.toString() ?? '0') ?? 0.0;
    double totalExpense = double.tryParse(summary['total_expense']?.toString() ?? '0') ?? 0.0;
    double balance = totalIncome - totalExpense;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Balance', style: GoogleFonts.montserrat(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('£${balance.toStringAsFixed(2)}',
                style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.bold, color: themeColor)),
          ],
        ),
      ),
    );
  }

  // -------------------- BAR CHART ----------------------
  Widget _buildAnimatedBarChart() {
    double totalIncome = double.tryParse(summary['total_income']?.toString() ?? '0') ?? 0;
    double totalExpense = double.tryParse(summary['total_expense']?.toString() ?? '0') ?? 0;

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (totalIncome > totalExpense ? totalIncome : totalExpense) * 1.4,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  switch (value.toInt()) {
                    case 0:
                      return const Text('Income');
                    case 1:
                      return const Text('Expense');
                    default:
                      return const Text('');
                  }
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [
              BarChartRodData(
                  toY: totalIncome,
                  width: 30,
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8))
            ]),
            BarChartGroupData(x: 1, barRods: [
              BarChartRodData(
                  toY: totalExpense,
                  width: 30,
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8))
            ]),
          ],
        ),
      ),
    );
  }

  // -------------------- DONUT CHART ----------------------
  Widget _buildDonutChart() {
    double totalIncome = double.tryParse(summary['total_income']?.toString() ?? '0') ?? 0;
    double totalExpense = double.tryParse(summary['total_expense']?.toString() ?? '0') ?? 0;

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          centerSpaceRadius: 50,
          sections: [
            PieChartSectionData(
              value: totalIncome,
              color: Colors.green,
              title: 'Income',
              radius: 50,
              titleStyle: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            PieChartSectionData(
              value: totalExpense,
              color: Colors.red,
              title: 'Expense',
              radius: 50,
              titleStyle: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- FILTER BUTTONS ----------------------
  Widget _buildFilterButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _filterButton('All', 'all'),
        _filterButton('Income', 'income'),
        _filterButton('Expense', 'expense'),
      ],
    );
  }

  Widget _filterButton(String label, String value) {
    final bool isSelected = filter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: OutlinedButton(
        onPressed: () => setState(() => filter = value),
        style: OutlinedButton.styleFrom(
            side: BorderSide(color: isSelected ? themeColor : Colors.grey),
            backgroundColor: isSelected ? themeColor.withOpacity(0.1) : Colors.transparent),
        child: Text(label,
            style: GoogleFonts.montserrat(
                color: isSelected ? themeColor : Colors.grey[700], fontWeight: FontWeight.bold)),
      ),
    );
  }

  // -------------------- TRANSACTIONS ----------------------
  Widget _buildTransactionTile(dynamic txn) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: txn['type'] == 'income' ? Colors.green[100] : Colors.red[100],
        child: Icon(txn['type'] == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
            color: txn['type'] == 'income' ? Colors.green : Colors.red),
      ),
      title: Text(
        "£${txn['amount']}",
        style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
      ),
      subtitle: Text("${txn['type'].toUpperCase()} | ${txn['payment_method'] ?? 'N/A'}"),
      trailing: Text(txn['date'].toString().split('T')[0]),
    );
  }

  // -------------------- PRINT DIALOG ----------------------
  void _openPrintDialog() {
    DateTime? fromDate;
    DateTime? toDate;
    String format = 'pdf';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Export Statement'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(fromDate != null
                      ? fromDate.toString().split(' ')[0]
                      : 'Select From Date'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(const Duration(days: 30)),
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => fromDate = picked);
                  },
                ),
                ListTile(
                  title: Text(toDate != null
                      ? toDate.toString().split(' ')[0]
                      : 'Select To Date'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => toDate = picked);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField(
                  value: format,
                  items: const [
                    DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                    DropdownMenuItem(value: 'excel', child: Text('Excel')),
                  ],
                  onChanged: (val) => setState(() => format = val as String),
                  decoration: const InputDecoration(labelText: 'Select Format'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (fromDate != null && toDate != null) {
                    Navigator.pop(context);
                    _exportStatement(fromDate!, toDate!, format);
                  } else {
                    AppDialog.showWarningDialog(
                      context,
                      title: 'Select Dates',
                      message: 'Please select both From and To dates.',
                    );
                  }
                },
                child: const Text('Export'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportStatement(
      DateTime fromDate, DateTime toDate, String format) async {
    AppDialog.showLoadingDialog(context, message: 'Generating Statement...');

    final success = await _authService.exportFinanceStatement(
      fromDate: fromDate,
      toDate: toDate,
      format: format,
    );

    Navigator.pop(context); // Close loading dialog

    if (success) {
      AppDialog.showSuccessDialog(
        context,
        title: 'Export Requested',
        message: 'The statement will be sent to your email shortly.',
      );
    } else {
      AppDialog.showWarningDialog(
        context,
        title: 'Export Failed',
        message: 'Unable to generate statement. Please try again.',
      );
    }
  }

}
