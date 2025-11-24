import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // Untuk format tanggal Indonesia

// Import Providers
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';

// Import Screens
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  // Pastikan binding initialized sebelum menjalankan kode async lain
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi format tanggal untuk Locale Indonesia ('id_ID')
  // Ini penting agar DateFormat di Home Screen tidak error
  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // --- DAFTAR SEMUA PROVIDER DI SINI ---
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'SITEKAD Flutter',
        debugShowCheckedModeBanner: false,
        
        // Konfigurasi Tema (Warna Merah khas SITEKAD)
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD90429),
            primary: const Color(0xFFD90429),
          ),
          useMaterial3: true,
        ),
        
        // Widget pembuka untuk cek status login
        home: const AuthCheckWrapper(),
      ),
    );
  }
}

// --- WIDGET PENGECEK STATUS LOGIN ---
class AuthCheckWrapper extends StatefulWidget {
  const AuthCheckWrapper({super.key});

  @override
  State<AuthCheckWrapper> createState() => _AuthCheckWrapperState();
}

class _AuthCheckWrapperState extends State<AuthCheckWrapper> {
  @override
  void initState() {
    super.initState();
    // Cek status login setelah frame pertama dirender
    // Menggunakan addPostFrameCallback untuk menghindari error 'setState during build'
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<AuthProvider>(context, listen: false).checkLoginStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen perubahan pada AuthProvider
    final auth = Provider.of<AuthProvider>(context);
    
    // LOGIKA NAVIGASI:
    // Jika user terautentikasi (token ada) -> Masuk ke HomeScreen
    if (auth.isAuthenticated) {
      return const HomeScreen();
    } 
    
    // Jika belum login / token kosong -> Masuk ke AuthScreen (Login/Register)
    return const AuthScreen();
  }
}