import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart'; // PERBAIKAN 1: Import Dio ditambahkan kembali untuk tipe 'Response'
import '../services/api_service.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // --- STATE UTAMA ---
  UserProfile? _user;
  List<AttendanceRecord> _history = [];
  List<AttendanceRecord> _lemburHistory = [];
  bool _isLoading = false;

  // --- STATUS UI (Attendance) ---
  String _attendanceStatus = "Memuat status...";
  bool _canClockIn = false;
  bool _canClockOut = false;

  // --- STATUS UI (Lembur) ---
  String _lemburStatus = "Memuat...";
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

  // --- FETCH DATA GLOBAL ---
  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _fetchProfile(),
        _fetchHistory(),
        _fetchLemburHistory(),
      ]);
    } catch (e) {
      debugPrint("Error refreshing data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 1. FETCH PROFILE
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

  // 2. FETCH HISTORY & HITUNG STATUS ABSEN
  Future<void> _fetchHistory() async {
    try {
      final response = await _apiService.dio.get('/uhistori');
      if (response.statusCode == 200) {
        final List rawList = response.data['history'];
        
        _history = rawList.map((e) {
          String rawDate = e['tgl_absen'];
          DateTime dt = DateTime.parse(rawDate).toLocal();
          String dateStr = DateFormat('dd MMM yyyy', 'id_ID').format(dt);
          String dayStr = DateFormat('EEEE', 'id_ID').format(dt);
          
          return AttendanceRecord(
            date: dateStr,
            day: dayStr,
            clockIn: e['jam_masuk'] ?? '--:--',
            // PERBAIKAN 2: Gunakan operator ?? agar lebih ringkas
            clockOut: e['jam_keluar'] ?? '--:--',
          );
        }).toList();

        _calculateAttendanceStatus();
      }
    } catch (e) {
      debugPrint("Error history: $e");
    }
  }

  // 3. FETCH LEMBUR & HITUNG STATUS LEMBUR
  Future<void> _fetchLemburHistory() async {
    try {
      final response = await _apiService.dio.get('/lembur/history');
      if (response.statusCode == 200) {
        final List rawList = response.data['history'];
        
        _lemburHistory = rawList.map((e) {
          String rawDate = e['tgl_absen'];
          DateTime dt = DateTime.parse(rawDate).toLocal();
          String dateStr = DateFormat('dd MMM yyyy', 'id_ID').format(dt);
          String dayStr = DateFormat('EEEE', 'id_ID').format(dt);

          return AttendanceRecord(
            date: dateStr,
            day: dayStr,
            clockIn: e['jam_masuk'] ?? '--:--',
            // PERBAIKAN 2: Gunakan operator ?? agar lebih ringkas
            clockOut: e['jam_keluar'] ?? '--:--',
          );
        }).toList();

        _calculateLemburStatus();
      }
    } catch (e) {
      debugPrint("Error lembur history: $e");
    }
  }

  // --- LOGIKA PERHITUNGAN STATUS ---

  void _calculateAttendanceStatus() {
    final now = DateTime.now();
    final todayDate = DateFormat('dd MMM yyyy', 'id_ID').format(now);

    final staleSession = _history.firstWhere(
      (rec) => rec.clockOut == '--:--' && rec.date != todayDate,
      orElse: () => AttendanceRecord(date: '', day: '', clockIn: '', clockOut: ''),
    );

    final todaySession = _history.firstWhere(
      (rec) => rec.date == todayDate,
      orElse: () => AttendanceRecord(date: '', day: '', clockIn: '', clockOut: ''),
    );

    if (staleSession.date.isNotEmpty) {
      _attendanceStatus = "Anda belum Clock Out dari ${staleSession.day}, ${staleSession.date}";
      _canClockIn = false; 
      _canClockOut = true; 
    } 
    else if (todaySession.date.isNotEmpty) {
      if (todaySession.clockOut != '--:--') {
        _attendanceStatus = "Anda sudah absen hari ini.";
        _canClockIn = false;
        _canClockOut = false;
      } else {
        _attendanceStatus = "Hadir - Masuk pukul ${todaySession.clockIn}";
        _canClockIn = false;
        _canClockOut = true;
      }
    } else {
      _attendanceStatus = "Belum Absen Hari Ini";
      _canClockIn = true;
      _canClockOut = false;
    }
  }

  void _calculateLemburStatus() {
    final openLembur = _lemburHistory.firstWhere(
      (rec) => rec.clockOut == '--:--',
      orElse: () => AttendanceRecord(date: '', day: '', clockIn: '', clockOut: ''),
    );

    if (openLembur.date.isNotEmpty) {
      _lemburStatus = "Lembur - Masuk pukul ${openLembur.clockIn}";
      _isLemburClockedIn = true;
      _isLemburClockedOut = false;
    } else {
      _lemburStatus = "Belum Lembur Hari Ini";
      _isLemburClockedIn = false;
      _isLemburClockedOut = false;
    }
  }

  // --- ACTION: SUBMIT ABSEN ---
  Future<bool> submitAttendance({
    required double latitude,
    required double longitude,
    required String qrCode,
    required String type, 
  }) async {
    try {
      String androidId = "unknown";
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        androidId = androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        androidId = iosInfo.identifierForVendor ?? "ios_uuid";
      }

      String endpoint = '';
      // PERBAIKAN 3: Gunakan kurung kurawal {} untuk if/else
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

      // Tipe Response dari Dio
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