import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';

class ConfirmationScreen extends StatefulWidget {
  final String qrCode;
  final String type; // "in" atau "out"

  const ConfirmationScreen({
    super.key,
    required this.qrCode,
    required this.type,
  });

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  Position? _currentPosition;
  String _locationStatus = "Mencari lokasi...";
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
      if (!status.isGranted) {
        setState(() => _locationStatus = "Izin lokasi ditolak");
        return;
      }
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      setState(() => _locationStatus = "GPS tidak aktif");
      return;
    }

    try {
      // PERBAIKAN: Menggunakan LocationSettings alih-alih desiredAccuracy langsung
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _currentPosition = position;
        _locationStatus = "Lokasi ditemukan!";
      });
    } catch (e) {
      setState(() => _locationStatus = "Gagal mendapatkan lokasi: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final now = DateTime.now();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Konfirmasi Absensi")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.type == 'in' ? "KONFIRMASI CLOCK IN" : "KONFIRMASI CLOCK OUT",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildInfoRow("Waktu", DateFormat("HH:mm:ss").format(now)),
                    const Divider(height: 24),
                    _buildInfoRow("Tanggal", DateFormat("dd MMM yyyy", "id_ID").format(now)),
                    const Divider(height: 24),
                    _buildInfoRow("ID Lokasi (QR)", widget.qrCode),
                    const Divider(height: 24),
                    _buildInfoRow("Status Lokasi", _locationStatus, 
                      isStatus: true, 
                      isSuccess: _currentPosition != null
                    ),
                    if (_currentPosition != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "${_currentPosition!.latitude}, ${_currentPosition!.longitude}",
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_currentPosition == null || _isSubmitting)
                    ? null
                    : () async {
                        setState(() => _isSubmitting = true);
                        
                        // Simpan scaffoldMessenger di variabel sebelum async gap
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);

                        final success = await userProvider.submitAttendance(
                          latitude: _currentPosition!.latitude,
                          longitude: _currentPosition!.longitude,
                          qrCode: widget.qrCode,
                          type: widget.type,
                        );

                        setState(() => _isSubmitting = false);

                        // PERBAIKAN: Pengecekan mounted yang ketat
                        if (!mounted) return;

                        if (success) {
                          navigator.pop(); // Kembali ke Home
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(content: Text("Absensi Berhasil!"), backgroundColor: Colors.green),
                          );
                        } else {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(content: Text("Gagal absen. Coba lagi."), backgroundColor: Colors.red),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                    : const Text("KIRIM ABSEN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isStatus = false, bool isSuccess = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isStatus ? (isSuccess ? Colors.green : Colors.red) : Colors.black,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}