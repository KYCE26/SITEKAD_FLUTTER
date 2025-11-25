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
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () => userProvider.refreshData(),
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildWelcomeHeader(userProvider.user, theme),
          const SizedBox(height: 24),

          _buildClockCard(context, theme, userProvider),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Aktivitas Terkini", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              // TextButton(onPressed: () {}, child: const Text("Lihat Semua")),
            ],
          ),
          const SizedBox(height: 12),

          if (userProvider.history.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20), 
                child: Text("Belum ada aktivitas", style: TextStyle(color: theme.colorScheme.secondary))
              )
            )
          else
            ...userProvider.history.take(5).map((rec) => _buildHistoryItem(rec, theme)),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(UserProfile? user, ThemeData theme) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.primary, width: 2),
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.surface,
            child: Icon(Icons.person, size: 32, color: theme.colorScheme.onSurface),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.namaLengkap ?? "Loading...",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              user?.nitad ?? "...",
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClockCard(BuildContext context, ThemeData theme, UserProvider provider) {
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

    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      // Card Putih/Gelap dengan Border Merah Tipis
      elevation: 0,
      color: theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // JAM DIGITAL (WARNA MERAH)
            StreamBuilder<DateTime>(
              stream: _clockStream,
              builder: (_, snap) => Text(
                DateFormat('HH:mm:ss').format(snap.data ?? DateTime.now()),
                style: TextStyle(
                  fontSize: 52, 
                  fontWeight: FontWeight.bold, 
                  color: theme.colorScheme.primary, // Merah di sini!
                  letterSpacing: 2,
                ),
              ),
            ),
            Text(
              DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now()),
              style: TextStyle(fontSize: 16, color: theme.colorScheme.secondary),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            // Status Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20)
              ),
              child: Text(
                "Status: ${provider.attendanceStatus}", 
                style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            
            // Tombol Aksi
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: provider.canClockIn ? () => startScanning('in') : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary, // Tombol Masuk Merah Solid
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: const Text("Clock In"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: provider.canClockOut ? () => startScanning('out') : null,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.primary), // Tombol Keluar Outline Merah
                      foregroundColor: isDarkMode ? Colors.white : theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildHistoryItem(AttendanceRecord record, ThemeData theme) {
    bool isOk = !record.isLate;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isOk ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOk ? Icons.check_circle : Icons.warning_rounded,
              color: isOk ? Colors.green : Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.date, 
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 4),
                Text(
                  "Masuk: ${record.clockIn} • Keluar: ${record.clockOut}",
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}