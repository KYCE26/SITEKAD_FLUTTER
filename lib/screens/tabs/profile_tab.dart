import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = userProvider.user;

    // PERBAIKAN: Tambah Kurung Kurawal
    if (user == null) {
      return const Center(child: Text("Data user tidak ditemukan"));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                child: const Icon(Icons.person, size: 60, color: Colors.grey),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            user.namaLengkap,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ),
        Center(
          child: Text(
            user.nitad,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
        const SizedBox(height: 32),

        const Text("Informasi Pekerjaan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _buildInfoTile(Icons.work, "Jabatan", user.jabatan),
              const Divider(height: 1),
              _buildInfoTile(Icons.business, "Cabang", user.cabang),
              const Divider(height: 1),
              _buildInfoTile(Icons.location_on, "Lokasi", user.lokasi),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text("Pengaturan Aplikasi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text("Mode Gelap"),
                subtitle: const Text("Ganti tampilan aplikasi ke gelap"),
                secondary: Icon(Icons.dark_mode, color: Theme.of(context).colorScheme.primary),
                value: themeProvider.isDarkMode,
                onChanged: (val) => themeProvider.toggleTheme(val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Konfirmasi Logout"),
                  content: const Text("Apakah Anda yakin ingin keluar?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        authProvider.logout();
                      },
                      child: const Text("Keluar", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
            ),
            child: const Text("Log Out"),
          ),
        ),
        const SizedBox(height: 20),
        const Center(child: Text("Versi 1.0.0", style: TextStyle(color: Colors.grey, fontSize: 12))),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
    );
  }
}