import 'dart:io'; // Untuk cek Platform (Android/iOS)
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart'; // Untuk Android ID
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  // Instance API Service
  final ApiService _apiService = ApiService();
  
  // State Variables
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  // Getters untuk UI
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  // --- LOGIC: LOGIN ---
  Future<bool> login(String username, String password) async {
    _setLoading(true);
    try {
      final response = await _apiService.dio.post('/login', data: {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        // Ambil token dari response JSON
        final token = response.data['token']; 
        
        // Simpan ke HP user
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        
        _isAuthenticated = true;
        _errorMessage = null;
        _setLoading(false);
        return true; // Login Sukses
      } else {
        _errorMessage = "Login Gagal: Kode ${response.statusCode}";
      }
    } on DioException catch (e) {
      // Handle error dari server (misal: Password salah)
      _errorMessage = e.response?.data.toString() ?? "Terjadi kesalahan koneksi";
    } catch (e) {
      _errorMessage = "Error tidak dikenal: $e";
    }
    
    _setLoading(false);
    return false; // Login Gagal
  }

  // --- LOGIC: REGISTER ---
  Future<bool> register(String fullname, String username, String password) async {
    _setLoading(true);
    try {
      // 1. Dapatkan Android ID (Unik per device)
      String androidId = "unknown_device_id";
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        androidId = androidInfo.id; // Ini pengganti Settings.Secure.ANDROID_ID
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        androidId = iosInfo.identifierForVendor ?? "ios_uuid";
      }

      // 2. Kirim Data ke API /aktivasi
      final response = await _apiService.dio.post('/aktivasi', data: {
        'NITAD': fullname, // Sesuai key JSON di Kotlin: "NITAD"
        'username': username,
        'password': password,
        'android_id': androidId
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        _errorMessage = null;
        _setLoading(false);
        return true; // Registrasi Sukses
      }
    } on DioException catch (e) {
      // Ambil pesan error dari server jika ada
      _errorMessage = e.response?.data.toString() ?? "Registrasi Gagal";
    } catch (e) {
      _errorMessage = "Error: $e";
    }

    _setLoading(false);
    return false;
  }

  // --- LOGIC: LOGOUT ---
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus token dan semua data sesi
    _isAuthenticated = false;
    notifyListeners();
  }

  // --- LOGIC: CEK STATUS LOGIN (AUTO LOGIN) ---
  // Dipanggil saat aplikasi pertama kali dibuka (Splash Screen)
  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    
    if (token != null && token.isNotEmpty) {
      _isAuthenticated = true;
    } else {
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  // Helper untuk update loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners(); // Memberitahu UI untuk rebuild (munculin loading spinner)
  }
}