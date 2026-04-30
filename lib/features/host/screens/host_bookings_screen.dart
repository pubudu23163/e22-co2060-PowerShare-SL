import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class HostBookingsScreen extends StatefulWidget {
  const HostBookingsScreen({super.key});
  @override
  State<HostBookingsScreen> createState() => _HostBookingsScreenState();
}

class _HostBookingsScreenState extends State<HostBookingsScreen> {
  static const Color _primary = Color(0xFF1E3A5F);
  List<dynamic> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _fetchBookings(); }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    final bookings = await ApiService.getReceivedBookings();
    setState(() { _bookings = bookings; _isLoading = false; });
  }

  Future<void> _acceptBooking(String id) async {
    final result = await ApiService.acceptBooking(id);
    if (result['success'] == true) {
      _showSnack('✅ Booking accepted!', isError: false);
      _fetchBookings();
    } else {
      _showSnack(result['message'] ?? 'Failed', isError: true);
    }
  }

  Future<void> _rejectBooking(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Booking?'),
        content: const Text('Driver-ට notify කරනවා. Sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final result = await ApiService.rejectBooking(id);
      if (result['success'] == true) {
        _showSnack('Booking rejected', isError: false);
        _fetchBookings();
      } else {
        _showSnack(result['message'] ?? 'Failed', isError: true);
      }
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed': return Colors.green;
      case 'pending_confirmation': return Colors.orange;  // ← add
      case 'pending':   return Colors.orange;
      case 'rejected':  return Colors.red;                // ← add
      case 'cancelled': return Colors.red;
      case 'completed': return Colors.blue;
      default:          return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Received Bookings'),
        backgroundColor: _primary, foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchBookings)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A5F)))
          : _bookings.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Bookings නෑ', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ]))
              : RefreshIndicator(
                  color: _primary, onRefresh: _fetchBookings,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bookings.length,
                    itemBuilder: (ctx, i) {
                      final b = _bookings[i];
                      final status = b['status'] ?? 'pending';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: status == 'pending_confirmation' || status == 'pending_confirmation'
                                ? Colors.orange.shade300
                                : Colors.grey.shade200,
                            width: status == 'pending_confirmation' ? 1.5 : 1,
                          ),
                        ),
                        child: Column(children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(b['chargerName'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A5F)))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status[0].toUpperCase() + status.substring(1),
                                    style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 8),
                              Row(children: [
                                const Icon(Icons.person, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(b['userName'] ?? '-', style: const TextStyle(fontSize: 13)),
                              ]),
                              const SizedBox(height: 4),
                              Row(children: [
                                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text('${b['date']} at ${b['time']}', style: const TextStyle(fontSize: 13)),
                                const Spacer(),
                                Text('Rs. ${b['totalPrice']?.toInt()}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                              ]),
                              if (status == 'pending_confirmation' || status == 'pending_confirmation')
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(children: [
                                    Icon(Icons.timer, size: 14, color: Colors.orange),
                                    SizedBox(width: 6),
                                    Text('1 hour ඇතුළත respond කරන්න — නැත්නම් auto cancel',
                                        style: TextStyle(fontSize: 11, color: Colors.orange)),
                                  ]),
                                ),
                            ]),
                          ),

                          // Accept/Reject buttons — pending only
                          if (status == 'pending_confirmation')
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                              ),
                              child: Row(children: [
                                Expanded(child: TextButton.icon(
                                  onPressed: () => _rejectBooking(b['_id']),
                                  icon: const Icon(Icons.close, color: Colors.red, size: 18),
                                  label: const Text('Reject', style: TextStyle(color: Colors.red)),
                                )),
                                Container(width: 1, height: 30, color: Colors.grey.shade200),
                                Expanded(child: TextButton.icon(
                                  onPressed: () => _acceptBooking(b['_id']),
                                  icon: const Icon(Icons.check, color: Colors.green, size: 18),
                                  label: const Text('Accept', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                )),
                              ]),
                            ),
                        ]),
                      );
                    },
                  ),
                ),
    );
  }
}
