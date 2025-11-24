import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Import ini untuk debugPrint
import 'package:intl/intl.dart';
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
      await Future.wait([
        _fetchProfile(),
        _fetchHistory(),
      ]);
    } catch (e) {
      debugPrint("Error refreshing data: $e");
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
      }
    } catch (e) {
      debugPrint("Error profile: $e");
    }
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await _apiService.dio.get('/api/uhistori');
      if (response.statusCode == 200) {
        final List rawList = response.data['history'];
        _history = rawList.map((e) => AttendanceRecord.fromApi(e)).toList();
        
        _calculateAttendanceStatus(); // Hitung logika tombol
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
    
    // Cek apakah record terakhir itu hari ini?
    final todayStr = DateFormat('dd MMM yyyy', 'id_ID').format(now); 
    
    // Jika tanggal di record SAMA dengan hari ini
    if (latestRecord.date.contains(todayStr) || latestRecord.date == todayStr) {
      // PERBAIKAN: Hapus check null karena clockOut dipastikan String di Model
      if (latestRecord.clockOut == "--:--:--") {
        // Masuk sudah, Keluar belum
        _setStatus("Sudah Clock In: ${latestRecord.clockIn}", canIn: false, canOut: true);
      } else {
        // Masuk sudah, Keluar sudah
        _setStatus("Selesai Absen Hari Ini", canIn: false, canOut: false);
      }
    } else {
      // Record terakhir BUKAN hari ini -> Berarti hari ini belum absen
      // TAPI cek dulu, jangan2 user lupa checkout kemarin (Stale Session)
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
}