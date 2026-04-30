import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/charger_model.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/role_selection_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import 'add_charger_screen.dart';
import 'host_bookings_screen.dart';

class HostDashboardScreen extends StatefulWidget {
  const HostDashboardScreen({super.key});

  @override
  State<HostDashboardScreen> createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends State<HostDashboardScreen> {
  static const Color _primary = Color(0xFF1E3A5F);
  List<ChargerModel> _myChargers = [];
  bool _isLoading = true;
  String _userName = '';
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final info = await AuthService().getUserInfo();
    setState(() => _userName = info['name'] ?? '');
    await _fetchMyChargers();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final count = await ApiService.getUnreadCount();
    setState(() => _unreadCount = count);
  }

  Future<void> _fetchMyChargers() async {
    setState(() => _isLoading = true);
    final chargers = await ApiService.getMyChargers();
    setState(() {
      _myChargers = chargers;
      _isLoading = false;
    });
  }

  Future<void> _toggleAvailability(ChargerModel charger) async {
    final result = await ApiService.toggleChargerAvailability(charger.id);
    if (result['success'] == true) {
      _fetchMyChargers();
    } else {
      _showSnack('Failed to update availability', isError: true);
    }
  }

  Future<void> _deleteCharger(ChargerModel charger) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Charger?'),
        content: Text('"${charger.name}" delete කරන්නද?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await ApiService.deleteCharger(charger.id);
      if (result['success'] == true) {
        _showSnack('Charger deleted!');
        _fetchMyChargers();
      } else {
        _showSnack('Delete failed', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Host Dashboard'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        actions: [
          // Notification bell with badge
          Stack(children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()),
                );
                _loadUnreadCount();
              },
            ),
            if (_unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  child: Text('$_unreadCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ),
          ]),
          // Switch role
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Switch Role',
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
            ),
          ),
          // Received bookings
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Received Bookings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HostBookingsScreen()),
            ),
          ),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _primary,
        onRefresh: _fetchMyChargers,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ආයුබෝවන්, ${_userName.split(' ').first}! 👋',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ඔබේ chargers ${_myChargers.length}ක් registered',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats row
              Row(
                children: [
                  _statCard('${_myChargers.length}', 'Total Chargers',
                      Icons.ev_station, Colors.blue),
                  const SizedBox(width: 12),
                  _statCard(
                      '${_myChargers.where((c) => c.isAvailable).length}',
                      'Available',
                      Icons.check_circle,
                      Colors.green),
                  const SizedBox(width: 12),
                  _statCard(
                      '${_myChargers.where((c) => !c.isAvailable).length}',
                      'Unavailable',
                      Icons.cancel,
                      Colors.red),
                ],
              ),
              const SizedBox(height: 24),

              // My Chargers header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Chargers',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final added = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddChargerScreen()),
                      );
                      if (added == true) _fetchMyChargers();
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add New'),
                    style: TextButton.styleFrom(foregroundColor: _primary),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Chargers list
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _myChargers.isEmpty
                      ? _buildEmpty()
                      : Column(
                          children: _myChargers
                              .map((c) => _buildChargerCard(c))
                              .toList(),
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.ev_station, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Charger නෑ!',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('ඔබේ first charger add කරන්න.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final added = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddChargerScreen()),
                );
                if (added == true) _fetchMyChargers();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Charger'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChargerCard(ChargerModel charger) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.ev_station,
                    color:
                        charger.isAvailable ? Colors.green : Colors.red,
                    size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(charger.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      Text(charger.address,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Text('Rs. ${charger.pricePerKwh.toInt()}/hr',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A5F))),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _toggleAvailability(charger),
                    icon: Icon(
                      charger.isAvailable
                          ? Icons.toggle_on
                          : Icons.toggle_off,
                      color: charger.isAvailable
                          ? Colors.green
                          : Colors.grey,
                    ),
                    label: Text(
                      charger.isAvailable ? 'Available' : 'Unavailable',
                      style: TextStyle(
                          color: charger.isAvailable
                              ? Colors.green
                              : Colors.grey,
                          fontSize: 13),
                    ),
                  ),
                ),
                Container(
                    width: 1, height: 30, color: Colors.grey.shade200),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _deleteCharger(charger),
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 18),
                    label: const Text('Remove',
                        style:
                            TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
