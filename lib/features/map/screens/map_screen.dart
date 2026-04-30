import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../models/charger_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../booking/screens/booking_screen.dart';
import '../../host/screens/add_charger_screen.dart';
import '../../booking/screens/my_bookings_screen.dart';
import '../../auth/screens/role_selection_screen.dart';
import '../../notifications/screens/notifications_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng _currentLocation = const LatLng(6.9271, 79.8612);
  ChargerModel? _selectedCharger;
  bool _isLoadingLocation = false;
  List<ChargerModel> _chargers = [];
  bool _isLoadingChargers = false;
  String? _chargerError;
  String _userName = '';
  String _userRole = 'driver';
  int _unreadCount = 0;
  bool _showLegend = false;

  // Filters
  String _filterType = 'All';
  bool _filterAvailable = false;

  List<ChargerModel> get _filteredChargers {
    return _chargers.where((c) {
      if (_filterAvailable && !c.isAvailable) return false;
      switch (_filterType) {
        case 'Slow':     return c.powerKw <= 3.3;
        case 'Standard': return c.powerKw > 3.3 && c.powerKw <= 7.4;
        case 'Fast':     return c.powerKw > 7.4 && c.powerKw <= 22.0;
        case 'Rapid':    return c.powerKw > 22.0;
        default:         return true;
      }
    }).toList();
  }

  // ── Power level → color ───────────────────────────────────────────
  Color _chargerColor(ChargerModel c) {
    if (!c.isAvailable) return Colors.red;
    if (c.powerKw <= 3.3) return Colors.orange;
    if (c.powerKw <= 7.4) return Colors.blue;
    if (c.powerKw <= 22.0) return Colors.green;
    return Colors.purple;
  }

  String _chargerTypeLabel(ChargerModel c) {
    if (c.powerKw <= 3.3) return 'Slow';
    if (c.powerKw <= 7.4) return 'Standard';
    if (c.powerKw <= 22.0) return 'Fast';
    return 'Rapid';
  }

  IconData _chargerTypeIcon(ChargerModel c) {
    if (c.powerKw <= 3.3) return Icons.power_outlined;
    if (c.powerKw <= 7.4) return Icons.ev_station;
    if (c.powerKw <= 22.0) return Icons.flash_on;
    return Icons.bolt;
  }

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _getUserLocation();
    _fetchChargers();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final count = await ApiService.getUnreadCount();
    setState(() => _unreadCount = count);
  }

  Future<void> _loadUserInfo() async {
    final info = await AuthService().getUserInfo();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = info['name'] ?? '';
      _userRole = prefs.getString('user_role') ?? 'driver';
    });
  }

  Future<void> _getUserLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_currentLocation, 13.0);
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }
    setState(() => _isLoadingLocation = false);
  }

  Future<void> _fetchChargers() async {
    setState(() {
      _isLoadingChargers = true;
      _chargerError = null;
    });
    final chargers = await ApiService.getChargers();
    setState(() {
      _isLoadingChargers = false;
      if (chargers.isNotEmpty) {
        _chargers = chargers;
      } else {
        _chargerError = 'Chargers load කරන්න බැරි වුණා. Retry කරන්න.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', height: 28),
            const SizedBox(width: 8),
            const Text('PowerShare SL',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        actions: [
          if (_isLoadingLocation || _isLoadingChargers)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
            ),
          if (_userName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Center(
                child: Text(_userName.split(' ').first,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
              ),
            ),
          Stack(children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()));
                _loadUnreadCount();
              },
            ),
            if (_unreadCount > 0)
              Positioned(
                right: 8, top: 8,
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
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'My Bookings',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MyBookingsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Switch Role',
            onPressed: () => Navigator.pushReplacement(context,
                MaterialPageRoute(
                    builder: (_) => const RoleSelectionScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 10.0,
              onTap: (_, __) => setState(() {
                _selectedCharger = null;
                _showLegend = false;
              }),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.powershare_sl',
              ),
              MarkerLayer(
                markers: [
                  // User location
                  Marker(
                    point: _currentLocation,
                    width: 50, height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.my_location,
                          color: Colors.blue, size: 30),
                    ),
                  ),
                  // Filtered charger markers
                  ..._filteredChargers.map((charger) => Marker(
                        point: LatLng(charger.latitude, charger.longitude),
                        width: 48, height: 48,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCharger = charger),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _chargerColor(charger),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: _chargerColor(charger)
                                      .withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(_chargerTypeIcon(charger),
                                color: Colors.white, size: 22),
                          ),
                        ),
                      )),
                ],
              ),
            ],
          ),

          // Filter bar — top
          Positioned(
            top: 10, left: 12, right: 80,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All', Colors.grey),
                  _filterChip('Slow', Colors.orange),
                  _filterChip('Standard', Colors.blue),
                  _filterChip('Fast', Colors.green),
                  _filterChip('Rapid', Colors.purple),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(
                        () => _filterAvailable = !_filterAvailable),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _filterAvailable
                            ? Colors.green
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4)
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              size: 14,
                              color: _filterAvailable
                                  ? Colors.white
                                  : Colors.grey),
                          const SizedBox(width: 4),
                          Text('Available',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: _filterAvailable
                                      ? Colors.white
                                      : Colors.grey,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Legend button + panel
          Positioned(
            top: 10, right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () =>
                      setState(() => _showLegend = !_showLegend),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A5F),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6)
                      ],
                    ),
                    child: const Icon(Icons.layers,
                        color: Colors.white, size: 18),
                  ),
                ),
                if (_showLegend) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10)
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Charger Types',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF1E3A5F))),
                        const SizedBox(height: 8),
                        _legendItem(Colors.orange,
                            Icons.power_outlined, 'Slow (3.3 kW)'),
                        _legendItem(Colors.blue,
                            Icons.ev_station, 'Standard (7.4 kW)'),
                        _legendItem(
                            Colors.green, Icons.flash_on, 'Fast (22 kW)'),
                        _legendItem(
                            Colors.purple, Icons.bolt, 'Rapid (50 kW)'),
                        const Divider(height: 12),
                        _legendItem(
                            Colors.red, Icons.ev_station, 'Unavailable'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Error banner
          if (_chargerError != null)
            Positioned(
              top: 55, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_chargerError!,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13)),
                    ),
                    TextButton(
                      onPressed: _fetchChargers,
                      child: const Text('Retry',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),

          // Charger info card
          if (_selectedCharger != null)
            Positioned(
              bottom: 20, left: 16, right: 16,
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _chargerColor(_selectedCharger!)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _chargerTypeIcon(_selectedCharger!),
                              color: _chargerColor(_selectedCharger!),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selectedCharger!.name,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold)),
                                Text(
                                  '${_chargerTypeLabel(_selectedCharger!)} • ${_selectedCharger!.powerKw} kW',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          _chargerColor(_selectedCharger!),
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _selectedCharger!.isAvailable
                                  ? Colors.green
                                  : Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _selectedCharger!.isAvailable
                                  ? 'Available'
                                  : 'Busy',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(_selectedCharger!.address,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.amber, size: 14),
                          Text(' ${_selectedCharger!.rating}',
                              style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 12),
                          const Icon(Icons.person,
                              color: Colors.grey, size: 14),
                          Text(' ${_selectedCharger!.ownerName}',
                              style: const TextStyle(fontSize: 13)),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Rs. ${_selectedCharger!.pricePerKwh.toInt()}/kWh',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E3A5F),
                                    fontSize: 14),
                              ),
                              Text(
                                '≈ Rs. ${(_selectedCharger!.powerKw * _selectedCharger!.pricePerKwh).toStringAsFixed(0)}/hr',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _selectedCharger!.isAvailable
                              ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BookingScreen(
                                          charger: _selectedCharger!),
                                    ),
                                  )
                              : null,
                          icon: const Icon(Icons.bolt, size: 18),
                          label: const Text('Book Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A5F),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_userRole == 'host') ...[
            FloatingActionButton.extended(
              heroTag: 'add_charger',
              onPressed: () async {
                final added = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddChargerScreen()));
                if (added == true) _fetchChargers();
              },
              backgroundColor: Colors.green,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Charger',
                  style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 12),
          ],
          FloatingActionButton(
            heroTag: 'my_location',
            onPressed: _getUserLocation,
            backgroundColor: const Color(0xFF1E3A5F),
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String type, Color color) {
    final isSelected = _filterType == type;
    return GestureDetector(
      onTap: () => setState(() => _filterType = type),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? color : Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1), blurRadius: 4)
          ],
        ),
        child: Text(
          type,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _legendItem(Color color, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28, height: 28,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }
}