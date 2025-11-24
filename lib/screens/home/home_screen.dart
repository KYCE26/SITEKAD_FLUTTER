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
import '../leave/leave_screen.dart';

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
            // 1. Loading Awal
            if (userProvider.isLoading && userProvider.user == null) {
              return const Center(child: CircularProgressIndicator());
            }

            // 2. Error Gagal Load Profil
            if (!userProvider.isLoading && userProvider.user == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text("Gagal memuat data: ${userProvider.errorMsg ?? ''}"),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => userProvider.refreshData(),
                      child: const Text("Coba Lagi"),
                    ),
                  ],
                ),
              );
            }

            // 3. Tampilan Utama
            return ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                _buildUserHeader(userProvider.user),
                const SizedBox(height: 24),

                _buildClockSection(context, colorScheme, userProvider),
                const SizedBox(height: 24),

                // Menu Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildMenuCard(
                        icon: Icons.work_history,
                        title: "Lembur",
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LemburScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMenuCard(
                        icon: Icons.event_note,
                        title: "Cuti",
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LeaveScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                const Text("Riwayat Kehadiran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),

                if (userProvider.history.isEmpty)
                  const Card(child: Padding(padding: EdgeInsets.all(16), child: Center(child: Text("Belum ada riwayat"))))
                else
                  ...userProvider.history.map((rec) => _buildHistoryItem(rec, colorScheme)),
                  
                const SizedBox(height: 50),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserHeader(UserProfile? user) {
    return Row(
      children: [
        const CircleAvatar(radius: 30, child: Icon(Icons.person, size: 30)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.namaLengkap ?? "-",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
              Text(user?.nitad ?? "-", style: const TextStyle(color: Colors.grey)),
              Text(user?.jabatan ?? "-", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
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
      elevation: 4,
      color: colors.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            Text(
              DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now()),
              style: TextStyle(fontSize: 14, color: colors.onPrimaryContainer.withOpacity(0.8)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20)
              ),
              child: Text(
                provider.attendanceStatus, 
                style: TextStyle(fontWeight: FontWeight.bold, color: colors.onPrimaryContainer),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.canClockIn ? () => startScanning('in') : null,
                    icon: const Icon(Icons.login),
                    label: const Text("MASUK"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.canClockOut ? () => startScanning('out') : null,
                    icon: const Icon(Icons.logout),
                    label: const Text("PULANG"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(AttendanceRecord record, ColorScheme colors) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: record.isLate ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            record.isLate ? Icons.warning_amber : Icons.check_circle,
            color: record.isLate ? Colors.red : Colors.green,
          ),
        ),
        title: Text(record.date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
          "Masuk: ${record.clockIn} • Keluar: ${record.clockOut}",
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}