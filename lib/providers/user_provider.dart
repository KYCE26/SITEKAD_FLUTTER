import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // --- STATE UTAMA ---
  UserProfile? _user;
  List<AttendanceRecord> _history = [];
  List<AttendanceRecord> _lemburHistory = [];
  bool _isLoading = false;
  
  // --- STATUS UI ---
  String _attendanceStatus = "Memuat status...";
  bool _canClockIn = false;
  bool _canClockOut = false;

  String _lemburStatus = "Memuat status...";
  bool _isLemburClockedIn = false;
  bool _isLemburClockedOut = false;

  // Getters
  UserProfile? get user => _user;
  List<AttendanceRecord> get history => _history;
  List<AttendanceRecord> get lemburHistory => _lemburHistory;
  bool get isLoading => _isLoading;
  
  String get attendanceStatus => _attendanceStatus;
  bool get canClockIn => _canClockIn;
  bool get canClockOut => _canClockOut;

  String get lemburStatus => _lemburStatus;
  bool get isLemburClockedIn => _isLemburClockedIn;
  bool get isLemburClockedOut => _isLemburClockedOut;

  // FUNGSI UTAMA
  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _fetchProfile();
      await _fetchHistory();
      await _fetchLemburHistory();
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

  Future<void> _fetchLemburHistory() async {
    try {
      final response = await _apiService.dio.get('/lembur/history');
      if (response.statusCode == 200) {
        final List rawList = response.data['history'] ?? [];
        _lemburHistory = rawList.map((e) => AttendanceRecord.fromApi(e)).toList();
        _calculateLemburStatus();
      }
    } catch (e) {
      debugPrint("Error lembur history: $e");
    }
  }

  // --- LOGIKA STATUS ---

  void _calculateAttendanceStatus() {
    final now = DateTime.now();
    
    if (_history.isEmpty) {
      _setStatus("Belum Absen Hari Ini", canIn: true, canOut: false);
      return;
    }

    final latestRecord = _history.first;
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

  void _calculateLemburStatus() {
    _lemburStatus = "Belum Lembur Hari Ini";
    _isLemburClockedIn = false; 
    _isLemburClockedOut = false; 

    if (_lemburHistory.isEmpty) return;

    try {
      final openLembur = _lemburHistory.firstWhere(
        (rec) => rec.clockOut == '--:--' || rec.clockOut == "null"
      );
      _lemburStatus = "Sedang Lembur (Masuk: ${openLembur.clockIn})";
      _isLemburClockedIn = true; 
      _isLemburClockedOut = true; 
    } catch (e) {
      _lemburStatus = "Belum Lembur Hari Ini";
      _isLemburClockedIn = false;
      _isLemburClockedOut = false;
    }
  }

  // --- FUNGSI START LEMBUR ---
  Future<bool> startLembur({
    required File splFile,
    required double latitude,
    required double longitude,
    required String qrCode,
  }) async {
    try {
      String androidId = await _getAndroidId();
      
      String fileName = splFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        "latitude": latitude,
        "longitude": longitude,
        "android_id": androidId,
        "kodeqr": qrCode,
        "spl_file": await MultipartFile.fromFile(splFile.path, filename: fileName),
      });

      final response = await _apiService.dio.post('/lembur/start', data: formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await refreshData();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Start Lembur Error: $e");
      return false;
    }
  }

  // --- FUNGSI SUBMIT ABSEN ---
  Future<bool> submitAttendance({
    required double latitude,
    required double longitude,
    required String qrCode,
    required String type, 
  }) async {
    try {
      String androidId = await _getAndroidId();

      String endpoint = '';
      // PERBAIKAN: Pakai kurung kurawal {} agar linter senang
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

      Response response;
      if (type == 'out-lembur') {
         response = await _apiService.dio.put(endpoint, data: data);
      } else {
         response = await _apiService.dio.post(endpoint, data: data);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        await refreshData();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error submit: $e");
      if (e.toString().contains("sudah absen") || e.toString().contains("Duplicate")) {
         await refreshData();
         return true;
      }
      return false;
    }
  }

  Future<String> _getAndroidId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? "ios_uuid";
    }
    return "unknown";
  }
}