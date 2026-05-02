import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class HostEarningsScreen extends StatefulWidget {
  const HostEarningsScreen({super.key});
  @override
  State<HostEarningsScreen> createState() => _HostEarningsScreenState();
}

class _HostEarningsScreenState extends State<HostEarningsScreen> {
  static const Color _primary = Color(0xFF1E3A5F);
  static const Color _walletGreen = Color(0xFF00897B);

  bool _isLoading = true;
  bool _isWithdrawing = false;
  double _walletBalance = 0;
  double _totalEarned = 0;
  List<dynamic> _receivedBookings = [];

  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load wallet from API
      final earnings = await ApiService.getHostEarnings();
      final bookings = await ApiService.getReceivedBookings();

      setState(() {
        _walletBalance = (earnings['walletBalance'] as num?)?.toDouble() ?? 0;
        _totalEarned = (earnings['totalEarned'] as num?)?.toDouble() ?? 0;
        _receivedBookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showWithdrawDialog() {
    _amountController.text = _walletBalance.toStringAsFixed(0);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _walletGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance,
                      color: _walletGreen, size: 24),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Withdraw Earnings',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Available: Rs. ${_walletBalance.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ]),
              ]),
              const SizedBox(height: 20),
              _field(_amountController, 'Amount (Rs.)', Icons.payments_outlined,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _field(_bankNameController, 'Bank Name', Icons.account_balance_outlined,
                  hint: 'e.g. Commercial Bank'),
              const SizedBox(height: 12),
              _field(_accountNumberController, 'Account Number', Icons.pin_outlined,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _field(_accountNameController, 'Account Holder Name', Icons.person_outline),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isWithdrawing ? null : () => _processWithdrawal(setModalState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _walletGreen,
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
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processWithdrawal(StateSetter setModalState) async {
    if (_bankNameController.text.isEmpty ||
        _accountNumberController.text.isEmpty ||
        _accountNameController.text.isEmpty ||
        _amountController.text.isEmpty) {
      _showSnack('සියලු fields fill කරන්න', isError: true);
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0 || amount > _walletBalance) {
      _showSnack('Invalid amount. Available: Rs. ${_walletBalance.toStringAsFixed(0)}', isError: true);
      return;
    }

    setModalState(() => _isWithdrawing = true);
    await Future.delayed(const Duration(seconds: 2));

    // Call API
    final result = await ApiService.requestWithdrawal(
      amount: amount,
      bankName: _bankNameController.text,
      accountNumber: _accountNumberController.text,
      accountName: _accountNameController.text,
    );

    setModalState(() => _isWithdrawing = false);

    if (!mounted) return;
    Navigator.pop(context);

    if (result['success'] == true) {
      setState(() {
        _walletBalance -= amount;
      });
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _walletGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: _walletGreen, size: 60),
            ),
            const SizedBox(height: 16),
            const Text('Withdrawal Requested!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Rs. ${amount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                    color: _walletGreen)),
            const SizedBox(height: 8),
            Text(_bankNameController.text,
                style: const TextStyle(color: Colors.grey)),
            Text(_accountNumberController.text,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            const Text('Processing time: 1-3 business days',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary, foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('OK'),
            ),
          ]),
        ),
      );
    } else {
      _showSnack(result['message'] ?? 'Withdrawal failed', isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final confirmedBookings = _receivedBookings
        .where((b) => b['status'] == 'confirmed' || b['status'] == 'completed')
        .toList();
    final pendingBookings = _receivedBookings
        .where((b) => b['status'] == 'pending' || b['status'] == 'pending_confirmation')
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _walletGreen))
          : RefreshIndicator(
              color: _walletGreen,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(children: [
                  // Wallet hero section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF00897B), Color(0xFF004D40)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(children: [
                      // Wallet logo
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded,
                            color: Colors.white, size: 48),
                      ),
                      const SizedBox(height: 16),
                      const Text('Available Balance',
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        'Rs. ${_walletBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Earned: Rs. ${_totalEarned.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      if (_walletBalance > 0)
                        ElevatedButton.icon(
                          onPressed: _showWithdrawDialog,
                          icon: const Icon(Icons.arrow_upward, size: 18),
                          label: const Text('Withdraw to Bank'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _walletGreen,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                    ]),
                  ),

                  // Stats row
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      _statCard(
                        '${confirmedBookings.length}',
                        'Completed',
                        Icons.check_circle_outline,
                        Colors.green,
                      ),
                      const SizedBox(width: 12),
                      _statCard(
                        '${pendingBookings.length}',
                        'Pending',
                        Icons.pending_outlined,
                        Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      _statCard(
                        '10%',
                        'Platform Fee',
                        Icons.percent,
                        Colors.grey,
                      ),
                    ]),
                  ),

                  // Transaction history
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Earnings History',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        if (_receivedBookings.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Column(children: [
                              Icon(Icons.receipt_long_outlined,
                                  size: 48, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('No transactions yet',
                                  style: TextStyle(color: Colors.grey)),
                            ]),
                          )
                        else
                          ..._receivedBookings.map((b) {
                            final status = b['status'] ?? '';
                            final price = (b['totalPrice'] as num?)?.toDouble() ?? 0;
                            final earning = price * 0.90;
                            final isConfirmed = status == 'confirmed' || status == 'completed';
                            final isPending = status == 'pending' || status == 'pending_confirmation';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: Row(children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isConfirmed
                                        ? Colors.green.withOpacity(0.1)
                                        : isPending
                                            ? Colors.orange.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isConfirmed
                                        ? Icons.arrow_downward
                                        : isPending
                                            ? Icons.pending
                                            : Icons.close,
                                    color: isConfirmed
                                        ? Colors.green
                                        : isPending
                                            ? Colors.orange
                                            : Colors.red,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                    Text(b['chargerName'] ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14),
                                        overflow: TextOverflow.ellipsis),
                                    Text(
                                      '${b['userName'] ?? ''} • ${b['date'] ?? ''}',
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                  ]),
                                ),
                                Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                  Text(
                                    isConfirmed
                                        ? '+Rs. ${earning.toStringAsFixed(0)}'
                                        : isPending
                                            ? 'Pending'
                                            : 'Cancelled',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isConfirmed
                                          ? _walletGreen
                                          : isPending
                                              ? Colors.orange
                                              : Colors.red,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isConfirmed
                                          ? Colors.green.withOpacity(0.1)
                                          : isPending
                                              ? Colors.orange.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      isConfirmed ? 'Earned' : isPending ? 'Pending' : 'Cancelled',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isConfirmed
                                            ? Colors.green
                                            : isPending
                                                ? Colors.orange
                                                : Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ]),
                              ]),
                            );
                          }).toList(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
      ),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}