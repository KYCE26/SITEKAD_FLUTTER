import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/user_model.dart'; 
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';

import '../attendance/scan_screen.dart';
import '../attendance/confirmation_screen.dart';
import '../overtime/lembur_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Stream<DateTime> _clockStream;

  @override
  void initState() {
    super.initState();
    _clockStream = Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => userProvider.refreshData(),
        child: Builder(
          builder: (context) {
            if (userProvider.isLoading && userProvider.user == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!userProvider.isLoading && userProvider.user == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text("Gagal memuat profil."),
                    ElevatedButton(
                      onPressed: () => userProvider.refreshData(),
                      child: const Text("Coba Lagi"),
                    ),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                _buildUserHeader(userProvider.user),
                const SizedBox(height: 24),

                _buildClockSection(context, colorScheme, userProvider),
                const SizedBox(height: 24),

                _buildMenuCard(
                  icon: Icons.work_history,
                  title: "Lembur",
                  subtitle: "Pengajuan & Absensi Lembur",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LemburScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                
                _buildMenuCard(
                  icon: Icons.event_available,
                  title: "Pengajuan Cuti",
                  subtitle: "Ajukan cuti dengan melampirkan surat",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Fitur Cuti akan hadir segera")),
                    );
                  },
                ),
                const SizedBox(height: 24),

                const Text("Riwayat Kehadiran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),

                if (userProvider.history.isEmpty)
                  const Card(child: Padding(padding: EdgeInsets.all(16), child: Text("Belum ada riwayat")))
                else
                  // PERBAIKAN DI SINI: Menggunakan fungsi _buildHistoryItem agar tidak warning unused
                  ...userProvider.history.map((rec) => _buildHistoryItem(rec, colorScheme)),
                  
                const SizedBox(height: 50),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserHeader(user) {
    return Row(
      children: [
        const CircleAvatar(radius: 30, child: Icon(Icons.person)),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user?.namaLengkap ?? "-", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(user?.nitad ?? "-", style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildClockSection(BuildContext context, ColorScheme colors, UserProvider provider) {
    void startScanning(String type) async {
      final qrResult = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScanScreen()),
      );

      if (qrResult != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmationScreen(
              qrCode: qrResult,
              type: type,
            ),
          ),
        );
      }
    }

    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            StreamBuilder<DateTime>(
              stream: _clockStream,
              builder: (_, snap) => Text(
                DateFormat('HH:mm:ss').format(snap.data ?? DateTime.now()),
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: colors.onPrimaryContainer),
              ),
            ),
            const SizedBox(height: 16),
            Text(provider.attendanceStatus, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: provider.canClockIn ? () => startScanning('in') : null,
                    child: const Text("Clock IN"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: provider.canClockOut ? () => startScanning('out') : null,
                    child: const Text("Clock OUT"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.onSecondaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(AttendanceRecord record, ColorScheme colors) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: Text(record.date, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Masuk: ${record.clockIn} - Keluar: ${record.clockOut}"),
      ),
    );
  }
}