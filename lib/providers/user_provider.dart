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

  UserProfile? _user;
  List<AttendanceRecord> _history = [];
  List<AttendanceRecord> _lemburHistory = [];
  bool _isLoading = false;

  // Status Absensi UI
  String _attendanceStatus = "Memuat status...";
  bool _canClockIn = false;
  bool _canClockOut = false;

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

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Kita pisah try-catch nya supaya kalau satu gagal, yang lain tetap muncul
      await _fetchProfile(); 
      await _fetchHistory();
      await _fetchLemburHistory();
    } catch (e) {
      debugPrint("Global Error refreshing data: $e");
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
        debugPrint("Profile Success: ${_user?.namaLengkap}");
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await _apiService.dio.get('/uhistori');
      if (response.statusCode == 200) {
        final List rawList = response.data['history'];
        
        _history = [];
        for (var e in rawList) {
          try {
            // SAFETY: Cek null sebelum parsing
            String rawDate = e['tgl_absen'] ?? "";
            String dateStr = rawDate;
            String dayStr = "";

            // Coba format tanggal, jika gagal pakai raw string
            if (rawDate.isNotEmpty) {
              try {
                DateTime dt = DateTime.parse(rawDate).toLocal();
                dateStr = DateFormat('dd MMM yyyy', 'id_ID').format(dt);
                dayStr = DateFormat('EEEE', 'id_ID').format(dt);
              } catch (parseError) {
                debugPrint("Date parse error: $parseError");
                dateStr = rawDate; // Fallback ke string asli
              }
            }

            _history.add(AttendanceRecord(
              date: dateStr,
              day: dayStr,
              clockIn: e['jam_masuk'] ?? '--:--',
              clockOut: e['jam_keluar'] ?? '--:--',
            ));
          } catch (itemError) {
            debugPrint("Skip corrupted item: $itemError");
          }
        }
        
        _calculateAttendanceStatus();
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
    }
  }

  Future<void> _fetchLemburHistory() async {
    try {
      final response = await _apiService.dio.get('/lembur/history');
      if (response.statusCode == 200) {
        final List rawList = response.data['history'];
        
        _lemburHistory = [];
        for (var e in rawList) {
           try {
            String rawDate = e['tgl_absen'] ?? "";
            String dateStr = rawDate;
            String dayStr = "";

            if (rawDate.isNotEmpty) {
              try {
                DateTime dt = DateTime.parse(rawDate).toLocal();
                dateStr = DateFormat('dd MMM yyyy', 'id_ID').format(dt);
                dayStr = DateFormat('EEEE', 'id_ID').format(dt);
              } catch (_) {}
            }

            _lemburHistory.add(AttendanceRecord(
              date: dateStr,
              day: dayStr,
              clockIn: e['jam_masuk'] ?? '--:--',
              clockOut: e['jam_keluar'] ?? '--:--',
            ));
           } catch (_) {}
        }

        _calculateLemburStatus();
      }
    } catch (e) {
      debugPrint("Error fetching lembur: $e");
    }
  }

  // --- LOGIKA PERHITUNGAN STATUS ---

  void _calculateAttendanceStatus() {
    final now = DateTime.now();
    final todayStr = DateFormat('dd MMM yyyy', 'id_ID').format(now); // Format Indo

    // Jika history kosong
    if (_history.isEmpty) {
      _setStatus("Belum Absen Hari Ini", canIn: true, canOut: false);
      return;
    }

    // Ambil record paling atas (asumsi sort DESC dari API)
    final latestRecord = _history.first;

    // Cek apakah record terakhir == Hari Ini?
    // Kita cek string-nya mengandung tanggal hari ini atau persis sama
    bool isToday = latestRecord.date == todayStr || latestRecord.date.contains(todayStr);

    // Perbaikan Logika Tanggal Mentah (Jika parsing gagal tadi, string masih ISO)
    if (!isToday && latestRecord.date.contains("T")) {
        // Coba cek manual ISO string
        try {
           final dt = DateTime.parse(latestRecord.date).toLocal(); // Parse ISO date dr fallback
           final recDate = DateFormat('dd MMM yyyy', 'id_ID').format(dt);
           isToday = recDate == todayStr;
        } catch (_) {}
    }

    if (isToday) {
      // DATA HARI INI DITEMUKAN
      if (latestRecord.clockOut == "--:--" || latestRecord.clockOut.isEmpty) {
        // Masuk ADA, Keluar KOSONG -> Masih Aktif
        _setStatus("Sudah Clock In: ${latestRecord.clockIn}", canIn: false, canOut: true);
      } else {
        // Masuk ADA, Keluar ADA -> Selesai
        _setStatus("Selesai Absen Hari Ini", canIn: false, canOut: false);
      }
    } else {
      // DATA TERAKHIR BUKAN HARI INI
      // Cek Stale Session (Lupa checkout kemarin)
      if (latestRecord.clockOut == "--:--" || latestRecord.clockOut.isEmpty) {
         // Kemarin lupa absen pulang
         _setStatus("Lupa Clock Out tanggal ${latestRecord.date}", canIn: false, canOut: true);
      } else {
         // Kemarin bersih, hari ini belum absen
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

  void _setStatus(String status, {required bool canIn, required bool canOut}) {
    _attendanceStatus = status;
    _canClockIn = canIn;
    _canClockOut = canOut;
    notifyListeners(); // Pastikan UI update
  }

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