import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart'; // Dipakai untuk FormData & Response
import '../services/api_service.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // --- STATE UTAMA ---
  UserProfile? _user;
  List<AttendanceRecord> _history = [];
  List<AttendanceRecord> _lemburHistory = [];
  bool _isLoading = false;
  String? _errorMsg; 

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
  String? get errorMsg => _errorMsg;
  
  String get attendanceStatus => _attendanceStatus;
  bool get canClockIn => _canClockIn;
  bool get canClockOut => _canClockOut;

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
      await _fetchLemburHistory();
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
      final response = await _apiService.dio.get('/api/profile');
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
      final response = await _apiService.dio.get('/api/uhistori');
      if (response.statusCode == 200) {
        final List rawList = response.data['history'] ?? [];
        _history = _parseRecords(rawList);
        _calculateAttendanceStatus();
      }
    } catch (e) {
      debugPrint("Skip history error: $e");
    }
  }

  Future<void> _fetchLemburHistory() async {
    try {
      final response = await _apiService.dio.get('/api/lembur/history');
      if (response.statusCode == 200) {
        final List rawList = response.data['history'] ?? [];
        _lemburHistory = _parseRecords(rawList);
        _calculateLemburStatus();
      }
    } catch (e) {
       debugPrint("Skip lembur error: $e");
    }
  }

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
    final now = DateTime.now();
    if (_history.isEmpty) {
      _setStatus("Belum Absen Hari Ini", canIn: true, canOut: false);
      return;
    }
    final latestRecord = _history.first;
    final todayStr = DateFormat('dd MMM yyyy', 'id_ID').format(now); 
    
    if (latestRecord.date.contains(todayStr) || latestRecord.date == todayStr) {
      if (latestRecord.clockOut == "--:--:--" || latestRecord.clockOut == "null") {
        _setStatus("Sudah Clock In: ${latestRecord.clockIn}", canIn: false, canOut: true);
      } else {
        _setStatus("Selesai Absen Hari Ini", canIn: false, canOut: false);
      }
    } else {
      if (latestRecord.clockOut == "--:--:--" || latestRecord.clockOut == "null") {
         _setStatus("Anda lupa Clock Out tanggal ${latestRecord.date}!", canIn: false, canOut: true);
      } else {
         _setStatus("Belum Absen Hari Ini", canIn: true, canOut: false);
      }
    }
  }

  void _calculateLemburStatus() {
    if (_lemburHistory.isEmpty) {
       _lemburStatus = "Belum Lembur Hari Ini";
       _isLemburClockedIn = false;
       _isLemburClockedOut = false;
       return;
    }
    
    AttendanceRecord? openLembur;
    try {
      openLembur = _lemburHistory.firstWhere(
        (rec) => rec.clockOut == '--:--' || rec.clockOut == "null"
      );
    } catch (_) {}

    if (openLembur != null) {
      _lemburStatus = "Sedang Lembur: ${openLembur.clockIn}";
      _isLemburClockedIn = true;
      _isLemburClockedOut = true;
    } else {
      _lemburStatus = "Belum Lembur Hari Ini";
      _isLemburClockedIn = false;
      _isLemburClockedOut = false;
    }
  }

  void _setStatus(String status, {required bool canIn, required bool canOut}) {
    _attendanceStatus = status;
    _canClockIn = canIn;
    _canClockOut = canOut;
  }

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

      final response = await _apiService.dio.post('/api/lembur/start', data: formData);

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

  Future<bool> submitAttendance({
    required double latitude,
    required double longitude,
    required String qrCode,
    required String type, 
  }) async {
    try {
      String androidId = await _getAndroidId();

      String endpoint = '';
      if (type == 'in') {
        endpoint = '/api/absensi';
      } else if (type == 'out') {
        endpoint = '/api/absensi';
      } else if (type == 'out-lembur') {
        endpoint = '/api/lembur/end';
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

  // --- FUNGSI BARU: SUBMIT CUTI ---
  Future<bool> submitCuti({
    required String alasan,
    required String startDate, // yyyy-MM-dd
    required String endDate,   // yyyy-MM-dd
    required String description,
    File? suketFile,
  }) async {
    try {
      // Siapkan Map data dasar
      Map<String, dynamic> dataMap = {
        "alasan": alasan,
        "tanggal_mulai": startDate,
        "tanggal_selesai": endDate,
        "keterangan": description,
      };

      // Tambahkan file jika ada
      if (suketFile != null) {
        String fileName = suketFile.path.split('/').last;
        dataMap["suket"] = await MultipartFile.fromFile(suketFile.path, filename: fileName);
      }

      FormData formData = FormData.fromMap(dataMap);

      final response = await _apiService.dio.post('/api/cuti', data: formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Cuti biasanya tidak perlu refreshData real-time di Home, tapi boleh saja
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Submit Cuti Error: $e");
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