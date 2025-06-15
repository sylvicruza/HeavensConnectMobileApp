import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../services/auth_service.dart';
import '../../utils/app_dialog.dart';
import '../../utils/app_theme.dart';

class AdminFinanceDashboardScreen extends StatefulWidget {
  const AdminFinanceDashboardScreen({super.key});

  @override
  State<AdminFinanceDashboardScreen> createState() => _AdminFinanceDashboardScreenState();
}

class _AdminFinanceDashboardScreenState extends State<AdminFinanceDashboardScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final Color themeColor = AppTheme.themeColor;

  int selectedYear = DateTime.now().year;
  int currentMonth = DateTime.now().month;

  late PageController _pageController;
  late AnimationController _controller;

  List<dynamic> transactions = [];
  Map<String, dynamic> summary = {};
  String filter = 'all';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentMonth - 1);
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _loadFinanceData();
  }

  Future<void> _loadFinanceData() async {
    setState(() => isLoading = true);
    final s = await _authService.getFinanceSummary(year: selectedYear, month: currentMonth);
    final txns = await _authService.getFinanceTransactions(year: selectedYear, month: currentMonth);
    setState(() {
      summary = s ?? {};
      transactions = txns['transactions'] ?? [];
      isLoading = false;
    });
    _controller.forward(from: 0);
  }

  List<dynamic> get filteredTransactions {
    if (filter == 'income') return transactions.where((t) => t['type'] == 'income').toList();
    if (filter == 'expense') return transactions.where((t) => t['type'] == 'expense').toList();
    return transactions;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: Text('Analytics', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: themeColor)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: themeColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _openPrintDialog,
            tooltip: 'Print Statement',
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: 12,
              onPageChanged: (index) {
                setState(() => currentMonth = index + 1);
                _loadFinanceData();
              },
              itemBuilder: (context, index) {
                final monthName = _monthName(index + 1);
                return isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                  onRefresh: _loadFinanceData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        '$monthName $selectedYear',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: themeColor,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 10),
                      _buildSpentSummary(),
                      const SizedBox(height: 20),
                      _buildIncomeSummary(),
                      const SizedBox(height: 20),
                      _buildNetCashFlowWidget(),
                      const SizedBox(height: 20),
                      _buildTotalBalanceOverview(),
                      const SizedBox(height: 30),
                      Text('Tools', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 10),
                      ListTile(
                        leading: const Icon(Icons.picture_as_pdf),
                        title: const Text('Print Statement'),
                        onTap: _openPrintDialog,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) =>
      ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][month - 1];

  Widget _buildSpentSummary() {
    double totalExpense = double.tryParse(summary['total_expense']?.toString() ?? '0') ?? 0.0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spent', style: GoogleFonts.montserrat(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('£${totalExpense.toStringAsFixed(2)}',
                style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeSummary() {
    double totalIncome = double.tryParse(summary['total_income']?.toString() ?? '0') ?? 0.0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Income', style: GoogleFonts.montserrat(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('£${totalIncome.toStringAsFixed(2)}',
                style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBalanceOverview() {
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
            Text('Total Balance', style: GoogleFonts.montserrat(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('£${balance.toStringAsFixed(2)}',
                style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, color: themeColor)),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: themeColor, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('Cash', style: GoogleFonts.montserrat(fontSize: 14))
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetCashFlowWidget() {
    double totalIncome = double.tryParse(summary['total_income']?.toString() ?? '0') ?? 0.0;
    double totalExpense = double.tryParse(summary['total_expense']?.toString() ?? '0') ?? 0.0;
    double netFlow = totalIncome - totalExpense;

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      title: ChartTitle(text: 'Net Cashflow'),
      series: <CartesianSeries<dynamic, dynamic>>[
        ColumnSeries<dynamic, String>(
          dataSource: [
            ChartData('Income', totalIncome),
            ChartData('Expenses', totalExpense),
            ChartData('Net', netFlow),
          ],
          xValueMapper: (data, _) => data.label,
          yValueMapper: (data, _) => data.value,
          pointColorMapper: (data, _) => data.label == 'Net'
              ? Colors.blue
              : (data.label == 'Income' ? Colors.green : Colors.red),
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        )
      ],
    );
  }

  void _openPrintDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Finance Statement'),
        content: const Text('Would you like to export the statement as PDF or Excel?'),
        actions: [
          TextButton(
            onPressed: () => _exportStatement('pdf'),
            child: const Text('PDF'),
          ),
          TextButton(
            onPressed: () => _exportStatement('excel'),
            child: const Text('Excel'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportStatement(String format) async {
    final now = DateTime.now();
    final fromDate = DateTime(now.year, 1, 1);
    final toDate = DateTime(now.year, now.month, 31);

    final success = await _authService.exportFinanceStatement(
      fromDate: fromDate,
      toDate: toDate,
      format: format,
    );

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

class ChartData {
  final String label;
  final double value;

  ChartData(this.label, this.value);
}
