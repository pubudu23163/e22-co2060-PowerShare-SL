import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class HostEarningsScreen extends StatefulWidget {
  const HostEarningsScreen({super.key});
  @override
  State<HostEarningsScreen> createState() => _HostEarningsScreenState();
}

class _HostEarningsScreenState extends State<HostEarningsScreen> {
  static const Color _primary = Color(0xFF1E3A5F);
  bool _isLoading = true;
  bool _isWithdrawing = false;

  // Mock earnings data
  double _totalEarnings = 0;
  double _availableBalance = 0;
  double _pendingBalance = 0;
  List<Map<String, dynamic>> _transactions = [];

  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadEarnings() async {
    setState(() => _isLoading = true);

    // Get completed bookings and calculate earnings
    final bookings = await ApiService.getReceivedBookings();
    
    double total = 0;
    double available = 0;
    double pending = 0;
    List<Map<String, dynamic>> transactions = [];

    for (final b in bookings) {
      final status = b['status'] ?? '';
      final price = (b['totalPrice'] as num?)?.toDouble() ?? 0;
      final hostEarning = price * 0.90; // 90% to host (10% platform fee)

      if (status == 'confirmed' || status == 'completed') {
        total += hostEarning;
        available += hostEarning;
        transactions.add({
          'type': 'earning',
          'charger': b['chargerName'] ?? '',
          'driver': b['userName'] ?? '',
          'date': b['date'] ?? '',
          'amount': hostEarning,
          'status': 'completed',
        });
      } else if (status == 'pending') {
        pending += hostEarning;
        transactions.add({
          'type': 'earning',
          'charger': b['chargerName'] ?? '',
          'driver': b['userName'] ?? '',
          'date': b['date'] ?? '',
          'amount': hostEarning,
          'status': 'pending',
        });
      }
    }

    setState(() {
      _totalEarnings = total;
      _availableBalance = available;
      _pendingBalance = pending;
      _transactions = transactions.reversed.toList();
      _isLoading = false;
    });
  }

  void _showWithdrawDialog() {
    _amountController.text = _availableBalance.toStringAsFixed(0);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Withdraw Earnings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Available: Rs. ${_availableBalance.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            _field(_amountController, 'Amount (Rs.)', Icons.payments,
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _field(_bankNameController, 'Bank Name', Icons.account_balance,
                hint: 'e.g. Commercial Bank'),
            const SizedBox(height: 12),
            _field(_accountNumberController, 'Account Number', Icons.numbers,
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _field(_accountNameController, 'Account Holder Name', Icons.person),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isWithdrawing ? null : _processWithdrawal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isWithdrawing
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Request Withdrawal',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processWithdrawal() async {
    if (_amountController.text.isEmpty ||
        _bankNameController.text.isEmpty ||
        _accountNumberController.text.isEmpty ||
        _accountNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields required'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0 || amount > _availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid amount. Available: Rs. ${_availableBalance.toStringAsFixed(0)}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isWithdrawing = true);

    // Simulate processing
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isWithdrawing = false;
      _availableBalance -= amount;
      _transactions.insert(0, {
        'type': 'withdrawal',
        'bankName': _bankNameController.text,
        'accountNumber': _accountNumberController.text,
        'date': '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
        'amount': amount,
        'status': 'processing',
      });
    });

    if (mounted) {
      Navigator.pop(context); // close bottom sheet
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Request Submitted!'),
          ]),
          content: Text(
            'Withdrawal request of Rs. ${amount.toStringAsFixed(0)} submitted.\n\n'
            '🏦 ${_bankNameController.text}\n'
            '🔢 ${_accountNumberController.text}\n\n'
            'Processing time: 1-3 business days.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary, foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('My Earnings'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadEarnings),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A5F)))
          : RefreshIndicator(
              color: _primary,
              onRefresh: _loadEarnings,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(children: [

                  // Earnings summary cards
                  Row(children: [
                    _statCard('Total Earned',
                        'Rs. ${_totalEarnings.toStringAsFixed(0)}',
                        Icons.trending_up, Colors.blue),
                    const SizedBox(width: 10),
                    _statCard('Available',
                        'Rs. ${_availableBalance.toStringAsFixed(0)}',
                        Icons.account_balance_wallet, Colors.green),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    _statCard('Pending',
                        'Rs. ${_pendingBalance.toStringAsFixed(0)}',
                        Icons.pending, Colors.orange),
                    const SizedBox(width: 10),
                    _statCard('Platform Fee',
                        '10%', Icons.percent, Colors.grey),
                  ]),
                  const SizedBox(height: 20),

                  // Withdraw button
                  if (_availableBalance > 0)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showWithdrawDialog,
                        icon: const Icon(Icons.account_balance),
                        label: Text(
                            'Withdraw Rs. ${_availableBalance.toStringAsFixed(0)}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),

                  if (_availableBalance <= 0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Icon(Icons.info_outline, color: Colors.grey, size: 18),
                        SizedBox(width: 8),
                        Text('No funds available to withdraw',
                            style: TextStyle(color: Colors.grey)),
                      ]),
                    ),
                  const SizedBox(height: 24),

                  // Transaction history
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Transaction History',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),

                  _transactions.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No transactions yet',
                                style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      : Column(
                          children: _transactions
                              .map((t) => _transactionCard(t))
                              .toList(),
                        ),
                ]),
              ),
            ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      ),
    );
  }

  Widget _transactionCard(Map<String, dynamic> t) {
    final isEarning = t['type'] == 'earning';
    final isPending = t['status'] == 'pending';
    final isProcessing = t['status'] == 'processing';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isEarning
                ? Colors.green.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isEarning ? Icons.arrow_downward : Icons.arrow_upward,
            color: isEarning ? Colors.green : Colors.blue,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              isEarning
                  ? (t['charger'] ?? 'Charging session')
                  : 'Withdrawal → ${t['bankName']}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              isEarning
                  ? 'From: ${t['driver']} • ${t['date']}'
                  : 'Acc: ${t['accountNumber']} • ${t['date']}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            '${isEarning ? '+' : '-'}Rs. ${(t['amount'] as double).toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isEarning ? Colors.green : Colors.blue,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isPending || isProcessing
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isPending
                  ? 'Pending'
                  : isProcessing
                      ? 'Processing'
                      : 'Done',
              style: TextStyle(
                fontSize: 10,
                color: isPending || isProcessing ? Colors.orange : Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType, String? hint}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}