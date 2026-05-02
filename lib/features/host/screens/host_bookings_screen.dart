import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class HostBookingsScreen extends StatefulWidget {
  const HostBookingsScreen({super.key});
  @override
  State<HostBookingsScreen> createState() => _HostBookingsScreenState();
}

class _HostBookingsScreenState extends State<HostBookingsScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF1E3A5F);
  late TabController _tabController;
  List<dynamic> _allBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    final bookings = await ApiService.getReceivedBookings();
    setState(() {
      _allBookings = bookings;
      _isLoading = false;
    });
  }

  List<dynamic> get _pendingBookings => _allBookings
      .where((b) => b['status'] == 'pending' || b['status'] == 'pending_confirmation')
      .toList();

  List<dynamic> get _confirmedBookings => _allBookings
      .where((b) => b['status'] == 'confirmed' || b['status'] == 'completed')
      .toList();

  List<dynamic> get _cancelledBookings => _allBookings
      .where((b) => b['status'] == 'cancelled')
      .toList();

  // ✅ Accept booking
  Future<void> _acceptBooking(dynamic b) async {
    final confirm = await _confirmDialog(
      title: 'Accept Booking?',
      content: '${b['userName']}-ගේ booking accept කරන්නද?\n\n'
          '📍 ${b['chargerName']}\n'
          '📅 ${b['date']} at ${b['time']}\n'
          '💰 Rs. ${b['totalPrice']}',
      confirmText: 'Accept',
      confirmColor: Colors.green,
    );
    if (!confirm) return;

    final result = await ApiService.acceptBooking(b['_id']);
    if (result['success'] == true) {
      _showSnack('✅ Booking accepted! Rs.${((b['totalPrice'] as num) * 0.9).toStringAsFixed(0)} added to wallet');
      _fetchBookings();
    } else {
      _showSnack(result['message'] ?? 'Failed', isError: true);
    }
  }

  // ❌ Reject booking
  Future<void> _rejectBooking(dynamic b) async {
    final confirm = await _confirmDialog(
      title: 'Reject Booking?',
      content: '${b['userName']}-ගේ booking reject කරන්නද?\nDriver-ට notify කරනවා.',
      confirmText: 'Reject',
      confirmColor: Colors.red,
    );
    if (!confirm) return;

    final result = await ApiService.rejectBooking(b['_id']);
    if (result['success'] == true) {
      _showSnack('Booking rejected');
      _fetchBookings();
    } else {
      _showSnack(result['message'] ?? 'Failed', isError: true);
    }
  }

  Future<bool> _confirmDialog({
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(confirmText),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      duration: const Duration(seconds: 3),
    ));
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed':
      case 'completed':
        return Colors.green;
      case 'pending':
      case 'pending_confirmation':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'confirmed':   return 'Confirmed';
      case 'completed':   return 'Completed';
      case 'pending':
      case 'pending_confirmation': return 'Pending';
      case 'cancelled':   return 'Cancelled';
      default:            return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Received Bookings'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchBookings),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Pending'),
                if (_pendingBookings.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.orange, shape: BoxShape.circle),
                    child: Text('${_pendingBookings.length}',
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ]),
            ),
            const Tab(text: 'Confirmed'),
            const Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A5F)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_pendingBookings, showActions: true),
                _buildList(_confirmedBookings),
                _buildList(_cancelledBookings),
              ],
            ),
    );
  }

  Widget _buildList(List<dynamic> bookings, {bool showActions = false}) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            showActions ? Icons.pending_actions : Icons.inbox,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            showActions ? 'No pending bookings' : 'No bookings here',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ]),
      );
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: _fetchBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (ctx, i) => _buildCard(bookings[i], showActions: showActions),
      ),
    );
  }

  Widget _buildCard(dynamic b, {bool showActions = false}) {
    final status = b['status'] ?? 'pending';
    final price = (b['totalPrice'] as num?)?.toDouble() ?? 0;
    final hostEarning = price * 0.90;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: showActions
              ? Colors.orange.shade300
              : Colors.grey.shade200,
          width: showActions ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(
                  b['chargerName'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1E3A5F)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                      color: _statusColor(status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ),
            ]),
            const SizedBox(height: 10),

            // Driver info
            Row(children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(b['userName'] ?? '-',
                      style: const TextStyle(fontSize: 13))),
            ]),
            const SizedBox(height: 4),

            // Date/time
            Row(children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text('${b['date']} at ${b['time']}',
                  style: const TextStyle(fontSize: 13)),
              const Spacer(),
              const Icon(Icons.timer, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text('${b['durationHours']}h',
                  style: const TextStyle(fontSize: 13)),
            ]),
            const SizedBox(height: 4),

            // Price + earning
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Total: Rs. ${price.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
              Text(
                'Your earning: Rs. ${hostEarning.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00897B)),
              ),
            ]),

            // Timer warning for pending
            if (showActions) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(children: [
                  Icon(Icons.timer_outlined, size: 14, color: Colors.orange),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '1 hour ඇතුළත respond කරන්න',
                      style: TextStyle(fontSize: 11, color: Colors.orange),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ),
            ],
          ]),
        ),

        // Accept / Reject buttons
        if (showActions)
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(children: [
              // Reject
              Expanded(
                child: InkWell(
                  onTap: () => _rejectBooking(b),
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.close, color: Colors.red, size: 18),
                          SizedBox(width: 6),
                          Text('Reject',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600)),
                        ]),
                  ),
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              // Accept
              Expanded(
                child: InkWell(
                  onTap: () => _acceptBooking(b),
                  borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check, color: Colors.green, size: 18),
                          SizedBox(width: 6),
                          Text('Accept',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                        ]),
                  ),
                ),
              ),
            ]),
          ),
      ]),
    );
  }
}