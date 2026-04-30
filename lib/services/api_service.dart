import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/charger_model.dart';

class ApiService {
  static const String baseUrl =
      'https://e22-co2060-powershare-sl-production.up.railway.app';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── Auth ────────────────────────────────────────────────────────
  static Future<bool> loginWithGoogle({
    required String googleId,
    required String name,
    required String email,
    required String? photo,
    required String idToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'googleId': googleId,
          'name': name,
          'email': email,
          'photo': photo ?? '',
          'idToken': idToken,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', data['token']);
          await prefs.setString('user_id', data['user']['id']);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ─── Chargers ────────────────────────────────────────────────────
  static Future<List<ChargerModel>> getChargers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/chargers'),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List chargerList = data['chargers'];
          return chargerList.map((c) => ChargerModel.fromJson(c)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ─── Host — My Chargers ──────────────────────────────────────────
  static Future<List<ChargerModel>> getMyChargers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/chargers/my'),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List list = data['chargers'];
          return list.map((c) => ChargerModel.fromJson(c)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> toggleChargerAvailability(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/chargers/$id/availability'),
        headers: await _authHeaders(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteCharger(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/chargers/$id'),
        headers: await _authHeaders(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ─── Host — Received Bookings ─────────────────────────────────────
  static Future<List<dynamic>> getReceivedBookings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/bookings/received'),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['bookings'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ─── Notifications ────────────────────────────────────────────────
  static Future<List<dynamic>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications'),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['notifications'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<int> getUnreadCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/unread-count'),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<void> markNotificationRead(String id) async {
    try {
      await http.patch(
        Uri.parse('$baseUrl/api/notifications/$id/read'),
        headers: await _authHeaders(),
      );
    } catch (_) {}
  }

  static Future<void> markAllNotificationsRead() async {
    try {
      await http.patch(
        Uri.parse('$baseUrl/api/notifications/read-all'),
        headers: await _authHeaders(),
      );
    } catch (_) {}
  }

  // ─── Add Charger (Host) ──────────────────────────────────────────
  static Future<Map<String, dynamic>> addCharger({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required double pricePerKwh,
    required double powerKw,
    required String ownerName,
    required bool isAvailable,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/chargers'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'name': name,
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
          'pricePerKwh': pricePerKwh,
          'powerKw': powerKw,
          'ownerName': ownerName,
          'isAvailable': isAvailable,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'charger': data['charger']};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ─── Bookings ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> createBooking({
    required String chargerId,
    required String chargerName,
    required String chargerAddress,
    required String date,
    required String time,
    required double durationHours,
    required double totalPrice,
    required double estimatedKwh,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/bookings'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'chargerId': chargerId,
          'chargerName': chargerName,
          'chargerAddress': chargerAddress,
          'date': date,
          'time': time,
          'durationHours': durationHours,
          'totalPrice': totalPrice,
          'estimatedKwh': estimatedKwh,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'booking': data['booking']};
      }
      final data = jsonDecode(response.body);
      return {'success': false, 'message': data['message'] ?? 'Booking failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<List<dynamic>> getMyBookings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/bookings/my'),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['bookings'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> cancelBooking(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/bookings/$id/cancel'),
        headers: await _authHeaders(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Accept booking (Host)
  static Future<Map<String, dynamic>> acceptBooking(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/bookings/$id/confirm'),
        headers: await _authHeaders(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  //reject booking (Host)

  static Future<Map<String, dynamic>> rejectBooking(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/bookings/$id/reject'),
        headers: await _authHeaders(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}