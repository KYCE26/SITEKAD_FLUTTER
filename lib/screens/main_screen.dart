import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

// Import Tabs (Nanti kita buat di bawah)
import 'tabs/home_tab.dart';
import 'tabs/menu_tab.dart';
import 'tabs/profile_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Daftar Halaman
  final List<Widget> _tabs = [
    const HomeTab(),
    const MenuTab(),
    const ProfileTab(),
  ];

  final List<String> _titles = [
    "Dashboard",
    "Menu Layanan",
    "Profil Saya",
  ];

  @override
  void initState() {
    super.initState();
    // Refresh data user saat aplikasi pertama kali masuk Dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar dinamis sesuai tab
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      
      // Body menampilkan tab yang dipilih
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),

      // Navigasi Bawah yang Cantik
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}