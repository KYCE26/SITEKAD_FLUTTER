import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/user_model.dart'; 
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';

// Import Layar Baru
import '../attendance/scan_screen.dart';
import '../attendance/confirmation_screen.dart';

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
      body: RefreshIndicator(
        onRefresh: () => userProvider.refreshData(),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.1),
                    colorScheme.surface,
                  ],
                ),
              ),
            ),
            
            SafeArea(
              child: userProvider.isLoading && userProvider.user == null
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(24.0),
                      children: [
                        _buildUserHeader(userProvider.user, () {
                          authProvider.logout();
                        }),
                        const SizedBox(height: 24),

                        _buildClockSection(context, colorScheme, userProvider), // Context dikirim
                        const SizedBox(height: 24),

                        _buildMenuCard(
                          icon: Icons.event_available,
                          title: "Pengajuan Cuti",
                          subtitle: "Ajukan cuti dengan melampirkan surat",
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Fitur Cuti akan hadir di Langkah 4")),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Icon(Icons.history, color: colorScheme.primary),
                            const SizedBox(width: 12),
                            Text(
                              "Riwayat Kehadiran",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (userProvider.history.isEmpty)
                          const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Belum ada data")))
                        else
                          ...userProvider.history.map((record) => _buildHistoryItem(record, colorScheme)),
                          
                        const SizedBox(height: 50),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(user, VoidCallback onLogout) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
          ),
          child: const Icon(Icons.person),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.namaLengkap ?? "Memuat...",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              user?.nitad ?? "...",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: onLogout,
          icon: Icon(Icons.exit_to_app, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      ],
    );
  }

  // --- UPDATE PENTING DI SINI: Navigasi ke ScanScreen ---
  Widget _buildClockSection(BuildContext context, ColorScheme colors, UserProvider provider) {
    
    // Fungsi Helper untuk Navigasi
    void startScanning(String type) async {
      // 1. Buka Layar Scan dan tunggu hasilnya (String QR Code)
      final qrResult = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScanScreen()),
      );

      // 2. Jika dapat QR Code, buka Layar Konfirmasi
      if (qrResult != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmationScreen(
              qrCode: qrResult,
              type: type, // 'in' atau 'out'
            ),
          ),
        );
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            StreamBuilder<DateTime>(
              stream: _clockStream,
              builder: (context, snapshot) {
                final now = snapshot.data ?? DateTime.now();
                return Column(
                  children: [
                    Text(
                      DateFormat('HH:mm:ss').format(now),
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: colors.primary),
                    ),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now),
                      style: TextStyle(fontSize: 16, color: colors.onSurface.withValues(alpha: 0.8)),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              "Status: ${provider.attendanceStatus}",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: provider.attendanceStatus.contains("Sudah") ? Colors.green : colors.onSurface
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: provider.canClockIn 
                        ? () => startScanning('in') // Trigger Scan IN
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Clock In"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: provider.canClockOut 
                        ? () => startScanning('out') // Trigger Scan OUT
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Clock Out"),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: record.isLate ? colors.errorContainer : colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                record.isLate ? Icons.warning : Icons.check_circle,
                color: record.isLate ? colors.onErrorContainer : colors.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.date, 
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Masuk: ${record.clockIn} - Keluar: ${record.clockOut}",
                    style: TextStyle(color: colors.onSurface.withValues(alpha: 0.7), fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}