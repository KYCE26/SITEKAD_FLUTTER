import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../attendance/scan_screen.dart';
import '../attendance/confirmation_screen.dart'; 

class LemburScreen extends StatefulWidget {
  const LemburScreen({super.key});

  @override
  State<LemburScreen> createState() => _LemburScreenState();
}

class _LemburScreenState extends State<LemburScreen> {
  File? _splFile;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _splFile = File(pickedFile.path);
      });
    }
  }

  void _startLemburFlow(BuildContext context) async {
    // 1. Validasi File
    if (_splFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wajib upload Surat Perintah Lembur (SPL)")),
      );
      return;
    }

    // PERBAIKAN: Simpan referensi Context SEBELUM Async Gap (Navigator)
    // Ini agar Linter tidak komplain 'use_build_context_synchronously'
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final provider = Provider.of<UserProvider>(context, listen: false);

    // 2. Buka Scanner (Async Gap terjadi di sini)
    final qrResult = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanScreen()),
    );

    // 3. Cek Hasil
    if (!mounted) return; // Cek apakah widget masih aktif
    if (qrResult == null) return; // Jika user kembali tanpa scan

    // 4. Proses Kirim
    setState(() => _isSubmitting = true);

    try {
      if (!await _checkLocationPermission()) {
        throw "Izin lokasi diperlukan";
      }
      
      // Ambil lokasi (Async Gap kedua)
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // Gunakan variabel 'provider' yang sudah disimpan di atas
      bool success = await provider.startLembur(
        splFile: _splFile!,
        latitude: position.latitude,
        longitude: position.longitude,
        qrCode: qrResult,
      );

      // Gunakan variabel 'scaffoldMessenger' yang sudah disimpan di atas
      if (success) {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text("Lembur Dimulai!"), backgroundColor: Colors.green));
        setState(() => _splFile = null);
      } else {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text("Gagal memulai lembur"), backgroundColor: Colors.red));
      }
    } catch (e) {
      // Gunakan scaffoldMessenger di catch juga
      scaffoldMessenger.showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<bool> _checkLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }
    return status.isGranted;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Pengajuan Lembur")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- CARD STATUS ---
            Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info, color: colorScheme.onPrimaryContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        userProvider.lemburStatus,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // --- AREA FORM ---
            if (!userProvider.isLemburClockedIn) ...[
              const Text("1. Upload SPL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                    image: _splFile != null 
                        ? DecorationImage(image: FileImage(_splFile!), fit: BoxFit.cover)
                        : null
                  ),
                  child: _splFile == null 
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload, size: 40, color: Colors.grey),
                            Text("Tap untuk upload foto", style: TextStyle(color: Colors.grey)),
                          ],
                        ) 
                      : null,
                ),
              ),
              if (_splFile != null)
                TextButton.icon(
                  onPressed: () => setState(() => _splFile = null),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text("Hapus Foto", style: TextStyle(color: Colors.red)),
                ),

              const SizedBox(height: 24),
              const Text("2. Absen Mulai", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : () => _startLemburFlow(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isSubmitting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                      : const Icon(Icons.qr_code_scanner),
                  label: Text(_isSubmitting ? "Memproses..." : "Scan QR & Mulai"),
                ),
              ),
            ] 
            else ...[
              const Text("Akhiri Sesi Lembur", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ScanScreen()),
                    ).then((qrResult) {
                      if (qrResult != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ConfirmationScreen(
                              qrCode: qrResult,
                              type: 'out-lembur', 
                            ),
                          ),
                        );
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text("Clock Out Lembur"),
                ),
              ),
            ],

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text("Riwayat Lembur", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),

            if (userProvider.lemburHistory.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: Text("Belum ada data lembur")))
            else
              ...userProvider.lemburHistory.map((rec) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.access_time_filled, color: Colors.orange),
                  title: Text(rec.date, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${rec.clockIn} - ${rec.clockOut}"),
                ),
              )),
          ],
        ),
      ),
    );
  }
}