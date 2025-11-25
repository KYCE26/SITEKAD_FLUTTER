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
    final theme = Theme.of(context);

    if (user == null) {
      return const Center(child: Text("Data user tidak ditemukan"));
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Avatar
        Center(
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 2),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.person, size: 60, color: theme.colorScheme.onSurface),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            user.namaLengkap,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Center(
          child: Text(
            user.nitad,
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.secondary),
          ),
        ),
        const SizedBox(height: 32),

        // Info Section
        Text("Detail Pekerjaan", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              _buildInfoTile(context, Icons.work_outline, "Jabatan", user.jabatan),
              Divider(height: 1, indent: 16, endIndent: 16, color: theme.dividerColor.withValues(alpha: 0.1)),
              _buildInfoTile(context, Icons.business_outlined, "Cabang", user.cabang),
              Divider(height: 1, indent: 16, endIndent: 16, color: theme.dividerColor.withValues(alpha: 0.1)),
              _buildInfoTile(context, Icons.location_on_outlined, "Lokasi", user.lokasi),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Settings Section
        Text("Pengaturan", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
          ),
          child: SwitchListTile(
            title: const Text("Mode Gelap"),
            secondary: Icon(Icons.dark_mode_outlined, color: theme.colorScheme.onSurface),
            value: themeProvider.isDarkMode,
            // PERBAIKAN: Hapus activeColor agar ikut tema (Primary Color)
            onChanged: (val) => themeProvider.toggleTheme(val),
          ),
        ),
        const SizedBox(height: 32),

        // Logout Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Konfirmasi"),
                  content: const Text("Yakin ingin keluar?"),
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
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text("Log Out", style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInfoTile(BuildContext context, IconData icon, String title, String value) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
      subtitle: Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}