import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class WalletScreen extends StatefulWidget {
  final String role; // 'driver' or 'host'
  const WalletScreen({super.key, required this.role});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF1E3A5F);
  bool _isLoading = true;
  Map<String, dynamic> _wallet = {};
  List<dynamic> _transactions = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWallet();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWallet() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getWallet();
    setState(() {
      _isLoading = false;
      if (data['success'] == true) {
        _wallet = data['wallet'] ?? {};
        _transactions = widget.role == 'host'
            ? (data['hostTransactions'] ?? [])
            : (data['driverTransactions'] ?? []);
      }
    });
  }

  Future<void> _showTopUpDialog() async {
    final amounts = [500, 1000, 2000, 5000];
    int? selected;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Top Up Wallet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select amount to add:',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: amounts.map((a) => GestureDetector(
                  onTap: () => setS(() => selected = a),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected == a ? _primary : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Rs. $a',
                        style: TextStyle(
                            color: selected == a
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.bold)),
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selected == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      final result =
                          await ApiService.topUpWallet(selected!.toDouble());
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(result['message'] ?? 'Top up done!'),
                        backgroundColor: result['success'] == true
                            ? Colors.green
                            : Colors.red,
                      ));
                      _loadWallet();
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white),
              child: const Text('Add Money'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showWithdrawDialog() async {
    final amountCtrl = TextEditingController();
    final bankCtrl = TextEditingController();
    final accCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Withdraw Earnings'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Available: Rs. ${(_wallet['hostWithdrawable'] ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _dialogField(amountCtrl, 'Amount (Rs.)',
                    TextInputType.number, (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final d = double.tryParse(v);
                  if (d == null || d <= 0) return 'Invalid amount';
                  if (d > (_wallet['hostWithdrawable'] ?? 0)) {
                    return 'Exceeds available balance';
                  }
                  return null;
                }),
                const SizedBox(height: 10),
                _dialogField(bankCtrl, 'Bank Name',
                    TextInputType.text,
                    (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 10),
                _dialogField(accCtrl, 'Account Number',
                    TextInputType.number,
                    (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 10),
                _dialogField(nameCtrl, 'Account Holder Name',
                    TextInputType.text,
                    (v) => v!.isEmpty ? 'Required' : null),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              final result = await ApiService.withdrawEarnings(
                amount: double.parse(amountCtrl.text),
                bankName: bankCtrl.text,
                accountNumber: accCtrl.text,
                accountName: nameCtrl.text,
              );
              if (!mounted) return;
              if (result['success'] == true) {
                _showWithdrawSuccess(result['details']);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result['message'] ?? 'Failed'),
                  backgroundColor: Colors.red,
                ));
              }
              _loadWallet();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawSuccess(Map<String, dynamic> details) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 12),
            const Text('Withdrawal Initiated!',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _detailRow('Amount',
                      'Rs. ${details['amount']}'),
                  _detailRow('Bank', details['bankName'] ?? '-'),
                  _detailRow('Account', details['accountNumber'] ?? '-'),
                  _detailRow('Status', details['status'] ?? '-'),
                  _detailRow(
                      'ETA', details['estimatedDays'] ?? '-'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHost = widget.role == 'host';
    final balance = isHost
        ? (_wallet['hostWithdrawable'] ?? 0.0)
        : (_wallet['walletBalance'] ?? 0.0);
    final totalEarned = _wallet['hostEarnings'] ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(isHost ? 'Host Wallet' : 'My Wallet'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _loadWallet),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Balance card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A5F), Color(0xFF1565C0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF1E3A5F).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHost ? 'Withdrawable Balance' : 'Wallet Balance',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rs. ${balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold),
                        ),
                        if (isHost) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Total Earned: Rs. ${totalEarned.toStringAsFixed(2)}',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 20),
                        // Action button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isHost
                                ? _showWithdrawDialog
                                : _showTopUpDialog,
                            icon: Icon(
                                isHost
                                    ? Icons.account_balance
                                    : Icons.add_card,
                                size: 18),
                            label: Text(
                                isHost ? 'Withdraw to Bank' : 'Top Up'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: _primary,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Transactions
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            isHost
                                ? 'Earning History'
                                : 'Payment History',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1E3A5F)),
                          ),
                        ),
                        const Divider(height: 1),
                        _transactions.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(
                                  child: Text('No transactions yet',
                                      style:
                                          TextStyle(color: Colors.grey)),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _transactions.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (_, i) {
                                  final t = _transactions[i];
                                  final isRefunded =
                                      t['paymentStatus'] == 'refunded';
                                  final amount =
                                      (t['totalPrice'] ?? 0).toStringAsFixed(2);
                                  return ListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isRefunded
                                            ? Colors.blue.withOpacity(0.1)
                                            : Colors.green.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isRefunded
                                            ? Icons.undo
                                            : (isHost
                                                ? Icons.arrow_downward
                                                : Icons.arrow_upward),
                                        color: isRefunded
                                            ? Colors.blue
                                            : Colors.green,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      t['chargerName'] ?? 'Unknown',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      '${t['date'] ?? ''} • ${t['status'] ?? ''}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey),
                                    ),
                                    trailing: Text(
                                      isRefunded
                                          ? '+Rs. $amount'
                                          : '-Rs. $amount',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isRefunded
                                            ? Colors.blue
                                            : Colors.green,
                                        fontSize: 14,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 13)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      );

  Widget _dialogField(
    TextEditingController ctrl,
    String label,
    TextInputType type,
    String? Function(String?) validator,
  ) =>
      TextFormField(
        controller: ctrl,
        keyboardType: type,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      );
}