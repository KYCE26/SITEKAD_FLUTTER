import 'package:flutter/material.dart';
import '../overtime/lembur_screen.dart';
import '../leave/leave_screen.dart';

class MenuTab extends StatelessWidget {
  const MenuTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // --- HEADER KEREN (Invisible App Bar) ---
          const SizedBox(height: 10),
          const Text(
            "Layanan",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          Text(
            "Pilih menu kebutuhan Anda",
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),
          
          // --- GRID MENU (Cuma 2: Lembur & Cuti) ---
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1, // Bentuk kotak sedikit lebar
            children: [
              _buildMenuCard(
                context,
                icon: Icons.access_time_filled_rounded,
                title: "Lembur",
                desc: "Input & Absen",
                color: Colors.orange, // Warna Ikon
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LemburScreen())),
              ),
              _buildMenuCard(
                context,
                icon: Icons.calendar_month_rounded,
                title: "Cuti",
                desc: "Formulir Izin",
                color: Colors.blue, // Warna Ikon
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveScreen())),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {
    required IconData icon, 
    required String title, 
    required String desc,
    required Color color, 
    required VoidCallback onTap
  }) {
    final theme = Theme.of(context);
    return Card(
      // Style Card Modern: Putih, Shadow haluuus banget
      elevation: 0,
      color: theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.05)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ikon dalam lingkaran transparan
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const Spacer(),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 4),
              Text(desc, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}