import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:device_info_plus/device_info_plus.dart'; 
import 'package:dio/dio.dart'; // Import Dio dipakai untuk tipe Response
import '../services/api_service.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  UserProfile? _user;
  List<AttendanceRecord> _history = [];
  bool _isLoading = false;
  
  // Status Absensi UI
  String _attendanceStatus = "Memuat status...";
  bool _canClockIn = false;
  bool _canClockOut = false;

  // Getters
  UserProfile? get user => _user;
  List<AttendanceRecord> get history => _history;
  bool get isLoading => _isLoading;
  String get attendanceStatus => _attendanceStatus;
  bool get canClockIn => _canClockIn;
  bool get canClockOut => _canClockOut;

  // FUNGSI UTAMA: Tarik semua data (Profil & History)
  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Kita panggil satu-satu biar kalau history error, profil tetap muncul
      await _fetchProfile();
      await _fetchHistory();
    } catch (e) {
      debugPrint("Error refreshing data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await _apiService.dio.get('/profile');
      if (response.statusCode == 200) {
        final data = response.data['profile'];
        _user = UserProfile.fromJson(data);
      }
    } catch (e) {
      debugPrint("Error profile: $e");
    }
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await _apiService.dio.get('/uhistori');
      if (response.statusCode == 200) {
        final List rawList = response.data['history'];
        _history = rawList.map((e) => AttendanceRecord.fromApi(e)).toList();
        _calculateAttendanceStatus(); 
      }
    } catch (e) {
      debugPrint("Error history: $e");
    }
  }

  // LOGIKA ABSENSI
  void _calculateAttendanceStatus() {
    final now = DateTime.now();
    
    if (_history.isEmpty) {
      _setStatus("Belum Absen Hari Ini", canIn: true, canOut: false);
      return;
    }

    final latestRecord = _history.first;
    // Pastikan Locale ID terinstall di main.dart
    final todayStr = DateFormat('dd MMM yyyy', 'id_ID').format(now); 
    
    if (latestRecord.date.contains(todayStr) || latestRecord.date == todayStr) {
      if (latestRecord.clockOut == "--:--:--") {
        _setStatus("Sudah Clock In: ${latestRecord.clockIn}", canIn: false, canOut: true);
      } else {
        _setStatus("Selesai Absen Hari Ini", canIn: false, canOut: false);
      }
    } else {
      if (latestRecord.clockOut == "--:--:--") {
         _setStatus("Anda lupa Clock Out tanggal ${latestRecord.date}!", canIn: false, canOut: true);
      } else {
         _setStatus("Belum Absen Hari Ini", canIn: true, canOut: false);
      }
    }
  }

  void _setStatus(String status, {required bool canIn, required bool canOut}) {
    _attendanceStatus = status;
    _canClockIn = canIn;
    _canClockOut = canOut;
  }

  // --- FUNGSI SUBMIT ABSENSI ---
  Future<bool> submitAttendance({
    required double latitude,
    required double longitude,
    required String qrCode,
    required String type, 
  }) async {
    try {
      // 1. Ambil Android ID
      String androidId = "unknown";
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        androidId = androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        androidId = iosInfo.identifierForVendor ?? "ios_uuid";
      }

      // 2. Tentukan Endpoint & Method
      String endpoint = '';
      if (type == 'in') {
        endpoint = '/absensi';
      } else if (type == 'out') {
        endpoint = '/absensi'; // Sesuaikan jika beda
      } else {
        // Fallback untuk lembur nanti
        endpoint = '/lembur/end'; 
      }
      
      final data = {
        "latitude": latitude,
        "longitude": longitude,
        "android_id": androidId,
        "kodeqr": qrCode
      };

      // Gunakan tipe Response dari Dio agar import tidak mubazir
      Response response;
      
      // Logic sementara: Kalau 'out-lembur' pakai PUT, selain itu POST
      // Sesuaikan dengan kebutuhan backend kamu nanti
      if (type == 'out-lembur') {
         response = await _apiService.dio.put(endpoint, data: data);
      } else {
         response = await _apiService.dio.post(endpoint, data: data);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        await refreshData();
        return true;
      } else {
        debugPrint("Submit gagal: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("Error submit attendance: $e");
      return false;
    }
  }
}