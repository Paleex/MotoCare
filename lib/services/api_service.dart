
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiService {
  // Backend Node.js + Express
  static const String baseUrl = 'http://localhost:3000/api';

  // =========================
  // LOGIN
  // =========================
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/login'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 15));

    print('LOGIN STATUS CODE: ${response.statusCode}');
    print('LOGIN RESPONSE BODY: ${response.body}');

    final dynamic result = jsonDecode(response.body);

    if (result is Map<String, dynamic>) {
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          result['status'] == true) {
        return result;
      }

      throw Exception(result['message'] ?? 'Login gagal');
    }

    throw Exception('Format response API tidak valid');
  }

  // =========================
  // REGISTER
  // =========================
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/register'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 15));

    print('REGISTER STATUS CODE: ${response.statusCode}');
    print('REGISTER RESPONSE BODY: ${response.body}');

    final dynamic result = jsonDecode(response.body);

    if (result is Map<String, dynamic>) {
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          result['status'] == true) {
        return result;
      }

      throw Exception(result['message'] ?? 'Registrasi gagal');
    }

    throw Exception('Format response API tidak valid');
  }

  // =========================
  // AMBIL DAFTAR MOTOR
  // =========================
  static Future<dynamic> getMotors() async {
    final token = await StorageService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token login tidak ditemukan. Silakan login kembali.');
    }

    final response = await http
        .get(
          Uri.parse('$baseUrl/motors'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    print('GET MOTORS STATUS: ${response.statusCode}');
    print('GET MOTORS RESPONSE: ${response.body}');

    final dynamic result = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return result;
    }

    if (result is Map<String, dynamic>) {
      throw Exception(
        result['message'] ?? 'Gagal mengambil data motor',
      );
    }

    throw Exception('Gagal mengambil data motor');
  }

  // =========================
  // TAMBAH MOTOR
  // =========================
  static Future<dynamic> addMotor(
    Map<String, dynamic> motor,
  ) async {
    final token = await StorageService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token login tidak ditemukan. Silakan login kembali.');
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/motors'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(motor),
        )
        .timeout(const Duration(seconds: 15));

    print('ADD MOTOR STATUS: ${response.statusCode}');
    print('ADD MOTOR RESPONSE: ${response.body}');

    final dynamic result = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return result;
    }

    if (result is Map<String, dynamic>) {
      return result;
    }

    throw Exception('Gagal menambahkan motor');
  }

  
  // =========================
  // AMBIL RIWAYAT SERVIS
  // =========================
  static Future<dynamic> getServices() async {
    final token = await StorageService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Silakan login kembali.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/services'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    final result = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return result;
    }

    if (result is Map<String, dynamic>) {
      throw Exception(
        result['message'] ?? 'Gagal mengambil riwayat servis',
      );
    }

    throw Exception('Gagal mengambil riwayat servis');
  }

  // =========================
  // TAMBAH RIWAYAT SERVIS
  // =========================
  static Future<dynamic> addService(
    Map<String, dynamic> service,
  ) async {
    final token = await StorageService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Silakan login kembali.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/services'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(service),
    ).timeout(const Duration(seconds: 15));

    final result = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return result;
    }

    if (result is Map<String, dynamic>) {
      throw Exception(
        result['message'] ?? 'Gagal menambahkan riwayat servis',
      );
    }

    throw Exception('Gagal menambahkan riwayat servis');
  }

  static Future<dynamic> getReminders() async {
  final token = await StorageService.getToken();

  final response = await http
      .get(
        Uri.parse('$baseUrl/reminders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      )
      .timeout(const Duration(seconds: 15));

  final result = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return result;
  }

  throw Exception(
    result['message'] ?? 'Gagal mengambil data pengingat',
  );
}

static Future<dynamic> addReminder({
  required String motorId,
  required String jenisServis,
  required String tanggalJatuhTempo,
  int? kilometerTarget,
  String? catatan,
}) async {
  final token = await StorageService.getToken();

  final body = <String, dynamic>{
    'motor_id': motorId,
    'jenis_servis': jenisServis,
    'tanggal_jatuh_tempo': tanggalJatuhTempo,
    'kilometer_target': kilometerTarget,
    'catatan': catatan ?? '',
  };

  final response = await http
      .post(
        Uri.parse('$baseUrl/reminders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      )
      .timeout(const Duration(seconds: 15));

  final result = jsonDecode(response.body);

  if (response.statusCode == 201) {
    return result;
  }

  throw Exception(
    result['message'] ?? 'Gagal menambahkan pengingat',
  );
}

static Future<dynamic> updateReminderStatus({
  required String reminderId,
  required String status,
}) async {
  final token = await StorageService.getToken();

  final response = await http
      .put(
        Uri.parse('$baseUrl/reminders/$reminderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      )
      .timeout(const Duration(seconds: 15));

  final result = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return result;
  }

  throw Exception(
    result['message'] ?? 'Gagal memperbarui status pengingat',
  );
}

  
  // =========================
  // CATATAN BIAYA
  // =========================

  // Ambil daftar pengeluaran
  static Future<dynamic> getExpenses() async {
    final token = await StorageService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Silakan login kembali.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/expenses'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    final result = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return result;
    }

    if (result is Map<String, dynamic>) {
      throw Exception(
        result['message'] ?? 'Gagal mengambil catatan biaya',
      );
    }

    throw Exception('Gagal mengambil catatan biaya');
  }

  // Tambah pengeluaran
  static Future<dynamic> addExpense({
    required String motorId,
    required String kategori,
    required String tanggal,
    required int biaya,
    String? keterangan,
  }) async {
    final token = await StorageService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Silakan login kembali.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/expenses'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'motor_id': motorId,
        'kategori': kategori,
        'tanggal': tanggal,
        'biaya': biaya,
        'keterangan': keterangan ?? '',
      }),
    ).timeout(const Duration(seconds: 15));

    final result = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return result;
    }

    if (result is Map<String, dynamic>) {
      throw Exception(
        result['message'] ?? 'Gagal menambahkan catatan biaya',
      );
    }

    throw Exception('Gagal menambahkan catatan biaya');
  }

  // Hapus pengeluaran
  static Future<dynamic> deleteExpense({
    required String expenseId,
  }) async {
    final token = await StorageService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Silakan login kembali.');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/expenses/$expenseId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    final result = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return result;
    }

    if (result is Map<String, dynamic>) {
      throw Exception(
        result['message'] ?? 'Gagal menghapus catatan biaya',
      );
    }

    throw Exception('Gagal menghapus catatan biaya');
  }




}
