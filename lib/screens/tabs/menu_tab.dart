import 'package:flutter/material.dart';
import '../overtime/lembur_screen.dart';
import '../leave/leave_screen.dart';

class MenuTab extends StatelessWidget {
  const MenuTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "Layanan Karyawan",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Grid Menu
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildMenuCard(
              context,
              icon: Icons.access_time_filled,
              title: "Lembur",
              desc: "Pengajuan & Absen",
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LemburScreen()),
              ),
            ),
            _buildMenuCard(
              context,
              icon: Icons.calendar_month,
              title: "Cuti",
              desc: "Formulir Izin",
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LeaveScreen()),
              ),
            ),
            // Bisa tambah menu lain di sini (Misal: Slip Gaji, Reimburse)
            _buildMenuCard(
              context,
              icon: Icons.receipt_long,
              title: "Slip Gaji",
              desc: "Segera Hadir",
              color: Colors.purple,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Fitur belum tersedia")),
                );
              },
            ),
            _buildMenuCard(
              context,
              icon: Icons.settings,
              title: "Pengaturan",
              desc: "Akun",
              color: Colors.grey,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                desc,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
