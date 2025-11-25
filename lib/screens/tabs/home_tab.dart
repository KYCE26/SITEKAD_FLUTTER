import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart'; 
import '../../providers/user_provider.dart';
import '../attendance/scan_screen.dart';
import '../attendance/confirmation_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late Stream<DateTime> _clockStream;

  @override
  void initState() {
    super.initState();
    _clockStream = Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () => userProvider.refreshData(),
      child: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildWelcomeHeader(userProvider.user),
          const SizedBox(height: 24),

          _buildClockCard(context, colorScheme, userProvider),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Aktivitas Terkini", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              TextButton(onPressed: () {}, child: const Text("Lihat Semua")),
            ],
          ),
          const SizedBox(height: 8),

          if (userProvider.history.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Belum ada aktivitas")))
          else
            ...userProvider.history.take(5).map((rec) => _buildHistoryItem(rec, colorScheme)),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(UserProfile? user) {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[200],
          child: const Icon(Icons.person, size: 30, color: Colors.grey),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Halo, Selamat Bekerja!", style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text(
              user?.namaLengkap ?? "Loading...",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClockCard(BuildContext context, ColorScheme colors, UserProvider provider) {
    void startScanning(String type) async {
      final qrResult = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScanScreen()),
      );

      if (qrResult != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmationScreen(qrCode: qrResult, type: type),
          ),
        );
      }
    }

    return Card(
      elevation: 4,
      color: colors.primary,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            StreamBuilder<DateTime>(
              stream: _clockStream,
              builder: (_, snap) => Text(
                DateFormat('HH:mm:ss').format(snap.data ?? DateTime.now()),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            Text(
              DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now()),
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                // PERBAIKAN: withValues
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20)
              ),
              child: Text(
                provider.attendanceStatus, 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
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
                      backgroundColor: const Color(0xFF2B2D42),
                      foregroundColor: Colors.white,
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

  Widget _buildHistoryItem(AttendanceRecord record, ColorScheme colors) {
    bool isOk = !record.isLate;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            // PERBAIKAN: withValues
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              // PERBAIKAN: withValues
              color: isOk ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOk ? Icons.check_circle : Icons.warning,
              color: isOk ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.date, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  "${record.clockIn} - ${record.clockOut}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}