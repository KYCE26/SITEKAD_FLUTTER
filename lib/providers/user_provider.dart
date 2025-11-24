import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:device_info_plus/device_info_plus.dart'; // Dipakai di submitAttendance
import 'package:dio/dio.dart'; // Dipakai untuk tipe Response
import '../services/api_service.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  UserProfile? _user;
  List<AttendanceRecord> _history = [];
  // Variabel ini sekarang akan DIPAKAI (Used)
  List<AttendanceRecord> _lemburHistory = [];
  
  bool _isLoading = false;
  String? _errorMsg; 

  // Status UI
  String _attendanceStatus = "-";
  bool _canClockIn = false;
  bool _canClockOut = false;
  
  // Status Lembur
  String _lemburStatus = "-";
  bool _isLemburClockedIn = false;
  bool _isLemburClockedOut = false;

  // --- GETTERS (Agar variabel privat _ terbaca oleh UI) ---
  UserProfile? get user => _user;
  List<AttendanceRecord> get history => _history;
  List<AttendanceRecord> get lemburHistory => _lemburHistory; // Getter ini bikin _lemburHistory jadi "Used"
  bool get isLoading => _isLoading;
  String? get errorMsg => _errorMsg;
  
  String get attendanceStatus => _attendanceStatus;
  bool get canClockIn => _canClockIn;
  bool get canClockOut => _canClockOut;

  // Getter Lembur (Bikin variabel lembur jadi "Used")
  String get lemburStatus => _lemburStatus;
  bool get isLemburClockedIn => _isLemburClockedIn;
  bool get isLemburClockedOut => _isLemburClockedOut;

  Future<void> refreshData() async {
    _isLoading = true;
    _errorMsg = null;
    notifyListeners();

    try {
      await _fetchProfile();
      await _fetchHistory();
      await _fetchLemburHistory(); // Panggil fungsi lembur
    } catch (e) {
      _errorMsg = "Global Error: $e";
      debugPrint(_errorMsg);
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
      } else {
        _errorMsg = "Gagal Profil: ${response.statusCode}";
      }
    } catch (e) {
      _errorMsg = "Exception Profil: $e";
      rethrow;
    }
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await _apiService.dio.get('/uhistori');
      if (response.statusCode == 200) {
        final List rawList = response.data['history'] ?? [];
        _history = _parseRecords(rawList);
        _calculateAttendanceStatus();
      }
    } catch (e) {
      debugPrint("Skip history error: $e");
    }
  }

  // Logic Fetch Lembur
  Future<void> _fetchLemburHistory() async {
    try {
      final response = await _apiService.dio.get('/lembur/history');
      if (response.statusCode == 200) {
        final List rawList = response.data['history'] ?? [];
        _lemburHistory = _parseRecords(rawList); // Isi variabel _lemburHistory
        _calculateLemburStatus(); // Hitung status
      }
    } catch (e) {
       debugPrint("Skip lembur error: $e");
    }
  }

  // Helper Parsing Biar Rapi & Aman
  List<AttendanceRecord> _parseRecords(List rawList) {
    List<AttendanceRecord> results = [];
    for (var e in rawList) {
      String dateStr = e['tgl_absen']?.toString() ?? "";
      String clockIn = e['jam_masuk']?.toString() ?? "--:--";
      String clockOut = e['jam_keluar']?.toString() ?? "--:--";
      
      String displayDate = dateStr;
      try {
          if(dateStr.isNotEmpty) {
            DateTime dt = DateTime.parse(dateStr).toLocal();
            displayDate = DateFormat('dd MMM yyyy', 'id_ID').format(dt);
          }
      } catch (_) {}

      results.add(AttendanceRecord(
        date: displayDate,
        day: "",
        clockIn: clockIn,
        clockOut: clockOut,
      ));
    }
    return results;
  }

  void _calculateAttendanceStatus() {
    if (_history.isEmpty) {
      _setStatus("Belum Absen", canIn: true, canOut: false);
      return;
    }
    final last = _history.first;
    final nowStr = DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.now());

    if (last.date.contains(nowStr)) {
       if (last.clockOut == "--:--" || last.clockOut == "null") {
         _setStatus("Sudah Masuk: ${last.clockIn}", canIn: false, canOut: true);
       } else {
         _setStatus("Selesai Hari Ini", canIn: false, canOut: false);
       }
    } else {
       if (last.clockOut == "--:--" || last.clockOut == "null") {
          _setStatus("Lupa Logout Kemarin!", canIn: false, canOut: true);
       } else {
          _setStatus("Belum Absen Hari Ini", canIn: true, canOut: false);
       }
    }
  }

  void _calculateLemburStatus() {
    if (_lemburHistory.isEmpty) {
       _lemburStatus = "Belum Lembur";
       _isLemburClockedIn = false;
       _isLemburClockedOut = false;
       return;
    }
    
    // Cari yang belum selesai
    final openLembur = _lemburHistory.firstWhere(
      (rec) => rec.clockOut == "--:--" || rec.clockOut == "null",
      orElse: () => AttendanceRecord(date: '', day: '', clockIn: '', clockOut: ''),
    );

    if (openLembur.date.isNotEmpty) {
      _lemburStatus = "Sedang Lembur: ${openLembur.clockIn}";
      _isLemburClockedIn = false;
      _isLemburClockedOut = true;
    } else {
      _lemburStatus = "Belum Lembur Hari Ini";
      _isLemburClockedIn = true; // Boleh mulai lembur
      _isLemburClockedOut = false;
    }
  }

  void _setStatus(String status, {required bool canIn, required bool canOut}) {
    _attendanceStatus = status;
    _canClockIn = canIn;
    _canClockOut = canOut;
  }

  // --- SUBMIT ABSENSI LENGKAP (Memakai Import Dio & DeviceInfo) ---
  Future<bool> submitAttendance({
    required double latitude,
    required double longitude,
    required String qrCode,
    required String type, 
  }) async {
    try {
      // 1. Pakai DeviceInfoPlugin (Import device_info_plus jadi kepakai)
      String androidId = "unknown";
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) { // Import dart:io jadi kepakai
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        androidId = androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        androidId = iosInfo.identifierForVendor ?? "ios_uuid";
      }

      String endpoint = '';
      if (type == 'in') {
        endpoint = '/absensi';
      } else if (type == 'out') {
        endpoint = '/absensi';
      } else if (type == 'out-lembur') {
        endpoint = '/lembur/end';
      }
      
      final data = {
        "latitude": latitude,
        "longitude": longitude,
        "android_id": androidId,
        "kodeqr": qrCode
      };

      // 2. Pakai Response Dio (Import dio jadi kepakai)
      Response response;
      if (type == 'out-lembur') {
        response = await _apiService.dio.put(endpoint, data: data);
      } else {
        response = await _apiService.dio.post(endpoint, data: data);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        await refreshData(); 
        return true;
      } else {
        debugPrint("Gagal Absen: ${response.statusCode} - ${response.data}");
        return false;
      }
    } catch (e) {
      debugPrint("Exception Absen: $e");
      if (e.toString().contains("sudah absen") || e.toString().contains("Duplicate")) {
         await refreshData();
         return true;
      }
      return false;
    }
  }
}