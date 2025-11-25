import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // Untuk format tanggal Indonesia

// --- IMPORT PROVIDERS ---
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';

// --- IMPORT SCREENS ---
import 'screens/auth/auth_screen.dart';
import 'screens/main_screen.dart'; // Layar utama dengan Navigasi Bawah

void main() async {
  // Pastikan binding initialized sebelum kode async
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi format tanggal bahasa Indonesia ('id_ID')
  // Ini wajib agar DateFormat('EEEE, dd MMMM yyyy', 'id_ID') tidak error
  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Daftar semua Provider di sini agar bisa diakses dari mana saja
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      // Gunakan Consumer agar MaterialApp me-rebuild saat tema berubah
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'SITEKAD Pro',
            debugShowCheckedModeBanner: false,
            
            // Tema diambil dari ThemeProvider (Dark/Light)
            theme: themeProvider.currentTheme,
            
            // Halaman awal: Cek status login dulu
            home: const AuthCheckWrapper(),
          );
        },
      ),
    );
  }
}

// --- WIDGET LOGIC STATUS LOGIN ---
class AuthCheckWrapper extends StatefulWidget {
  const AuthCheckWrapper({super.key});

  @override
  State<AuthCheckWrapper> createState() => _AuthCheckWrapperState();
}

class _AuthCheckWrapperState extends State<AuthCheckWrapper> {
  @override
  void initState() {
    super.initState();
    // Cek token di SharedPreferences saat aplikasi baru dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<AuthProvider>(context, listen: false).checkLoginStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    // LOGIKA NAVIGASI:
    // 1. Jika User Terautentikasi -> Masuk ke MainScreen (Dashboard dengan Tab)
    if (auth.isAuthenticated) {
      return const MainScreen(); 
    } 
    
    // 2. Jika Belum Login -> Masuk ke AuthScreen (Login/Register)
    return const AuthScreen();
  }
}