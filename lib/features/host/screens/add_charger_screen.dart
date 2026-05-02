import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/api_service.dart';

class AddChargerScreen extends StatefulWidget {
  const AddChargerScreen({super.key});

  @override
  State<AddChargerScreen> createState() => _AddChargerScreenState();
}

class _AddChargerScreenState extends State<AddChargerScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  bool _isAvailable = true;
  bool _manualAcceptance = false; 
  bool _isSubmitting = false;
  bool _isGettingLocation = false;

  // Charger type selection
  double _selectedPowerKw = 7.4;

  static const Color _primary = Color(0xFF1E3A5F);

  // Charger types with powerKw values
  final List<Map<String, dynamic>> _chargerTypes = [
    {
      'label': 'Slow (3.3 kW)',
      'subtitle': 'Home socket level',
      'powerKw': 3.3,
      'icon': Icons.power_outlined,
      'color': Colors.orange,
    },
    {
      'label': 'Standard (7.4 kW)',
      'subtitle': 'Home charger',
      'powerKw': 7.4,
      'icon': Icons.ev_station,
      'color': Colors.blue,
    },
    {
      'label': 'Fast (22 kW)',
      'subtitle': 'AC fast charger',
      'powerKw': 22.0,
      'icon': Icons.flash_on,
      'color': Colors.green,
    },
    {
      'label': 'Rapid (50 kW)',
      'subtitle': 'DC rapid charger',
      'powerKw': 50.0,
      'icon': Icons.bolt,
      'color': Colors.purple,
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _ownerNameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack('Location permission denied.', isError: true);
        return;
      }
      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latController.text = pos.latitude.toStringAsFixed(6);
        _lngController.text = pos.longitude.toStringAsFixed(6);
      });
      _showSnack('Location detected!');
    } catch (e) {
      _showSnack('Could not get location.', isError: true);
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _submitCharger() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final result = await ApiService.addCharger(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      latitude: double.parse(_latController.text.trim()),
      longitude: double.parse(_lngController.text.trim()),
      pricePerKwh: double.parse(_priceController.text.trim()),
      powerKw: _selectedPowerKw,
      ownerName: _ownerNameController.text.trim(),
      isAvailable: _isAvailable,
      manualAcceptance: _manualAcceptance,
    );

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (result['success'] == true) {
      _showSuccessDialog();
    } else {
      _showSnack(result['message'] ?? 'Failed to add charger.', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Charger Added!'),
          ],
        ),
        content: Text(
          '"${_nameController.text}" successfully registered!\n\n'
          'EV users can now find and book your charger on the map.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    ).then((shouldRefresh) {
      if (shouldRefresh == true && mounted) Navigator.pop(context, true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Register Your Charger'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F1FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Color(0xFF185FA5), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ඔබේ charger register කළ පසු EV users-ට map-ේ පෙනෙනවා.',
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFF0C447C)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Charger Details
              _sectionLabel('Charger Details'),
              const SizedBox(height: 12),

              _buildField(
                controller: _nameController,
                label: 'Charger Name',
                hint: 'e.g. My Home Charger - Colombo 07',
                icon: Icons.ev_station,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Name required' : null,
              ),
              const SizedBox(height: 14),

              _buildField(
                controller: _ownerNameController,
                label: 'Your Name',
                hint: 'e.g. Kamal Perera',
                icon: Icons.person,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Name required' : null,
              ),
              const SizedBox(height: 14),

              // Price per kWh
              _buildField(
                controller: _priceController,
                label: 'Price per kWh (Rs.)',
                hint: 'e.g. 50',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Price required';
                  if (double.tryParse(v) == null) return 'Enter valid number';
                  if (double.parse(v) <= 0) return 'Price must be > 0';
                  return null;
                },
              ),
              const SizedBox(height: 6),
              const Text(
                'Tip: Sri Lanka average electricity rate ≈ Rs. 40-60 per kWh',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Charger Type / Power
              _sectionLabel('Charger Type (Power Output)'),
              const SizedBox(height: 12),

              // Charger type selector cards
              ...(_chargerTypes.map((type) {
                final isSelected = _selectedPowerKw == type['powerKw'];
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedPowerKw = type['powerKw']),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (type['color'] as Color).withOpacity(0.1)
                          : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? type['color'] as Color
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(type['icon'] as IconData,
                            color: isSelected
                                ? type['color'] as Color
                                : Colors.grey,
                            size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type['label'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? type['color'] as Color
                                      : Colors.black87,
                                ),
                              ),
                              Text(
                                type['subtitle'] as String,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        // Estimated charge time
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '~${(40 / (type['powerKw'] as double)).toStringAsFixed(1)}h',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? type['color'] as Color
                                    : Colors.grey,
                              ),
                            ),
                            const Text('full charge',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? type['color'] as Color
                              : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              })),
              const SizedBox(height: 24),

              // Location
              _sectionLabel('Location'),
              const SizedBox(height: 12),

              _buildField(
                controller: _addressController,
                label: 'Full Address',
                hint: 'e.g. 42 Galle Road, Colombo 03',
                icon: Icons.location_on,
                maxLines: 2,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Address required' : null,
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isGettingLocation ? null : _useMyLocation,
                  icon: _isGettingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, size: 18),
                  label: Text(
                    _isGettingLocation
                        ? 'Getting location...'
                        : 'Use My Current Location',
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    side: const BorderSide(color: Color(0xFF1E3A5F)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _latController,
                      label: 'Latitude',
                      hint: '6.9271',
                      icon: Icons.pin_drop,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final d = double.tryParse(v);
                        if (d == null) return 'Invalid';
                        if (d < 5.9 || d > 9.9) return 'Sri Lanka?';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      controller: _lngController,
                      label: 'Longitude',
                      hint: '79.8612',
                      icon: Icons.pin_drop,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final d = double.tryParse(v);
                        if (d == null) return 'Invalid';
                        if (d < 79.5 || d > 81.9) return 'Sri Lanka?';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Availability
              _sectionLabel('Availability'),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: Text(
                    _isAvailable ? 'Available Now' : 'Not Available',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _isAvailable ? Colors.green : Colors.red,
                    ),
                  ),
                  subtitle: Text(
                    _isAvailable
                        ? 'EV users can book your charger'
                        : 'Hidden from EV users',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: _isAvailable,
                  activeColor: Colors.green,
                  onChanged: (val) => setState(() => _isAvailable = val),
                  secondary: Icon(
                    _isAvailable ? Icons.check_circle : Icons.cancel,
                    color: _isAvailable ? Colors.green : Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: Text(
                    _manualAcceptance ? 'Manual Acceptance ON' : 'Auto Confirm',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _manualAcceptance ? Colors.blue : Colors.green,
                    ),
                  ),
                  subtitle: Text(
                    _manualAcceptance
                        ? 'ඔබ manually booking confirm කරනවා'
                        : 'Bookings automatically confirmed',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: _manualAcceptance,
                  activeColor: Colors.blue,
                  onChanged: (val) => setState(() => _manualAcceptance = val),
                  secondary: Icon(
                    _manualAcceptance ? Icons.touch_app : Icons.auto_mode,
                    color: _manualAcceptance ? Colors.blue : Colors.green,
                  ),
                ),
              ),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitCharger,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_location_alt, size: 20),
                            SizedBox(width: 8),
                            Text('Register Charger',
                                style: TextStyle(fontSize: 16)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: _primary, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF1E3A5F), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}