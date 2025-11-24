class UserProfile {
  final String username;
  final String nitad;
  final String namaLengkap;
  final String jabatan;
  final String cabang;
  final String lokasi;

  UserProfile({
    required this.username,
    required this.nitad,
    required this.namaLengkap,
    required this.jabatan,
    required this.cabang,
    required this.lokasi,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: json['Username'] ?? '',
      nitad: json['NITAD'] ?? '',
      namaLengkap: json['Nama Lengkap'] ?? '',
      jabatan: json['Jabatan'] ?? '',
      cabang: json['Cabang'] ?? '',
      lokasi: json['Lokasi'] ?? '',
    );
  }
}

class AttendanceRecord {
  final String date; // Format: "dd MMM yyyy"
  final String day;  // Format: "Senin"
  final String clockIn;
  final String clockOut;
  final bool isLate;

  AttendanceRecord({
    required this.date,
    required this.day,
    required this.clockIn,
    required this.clockOut,
    this.isLate = false,
  });

  // Parsing pintar dari API
  factory AttendanceRecord.fromApi(Map<String, dynamic> json) {
    // Kita ambil raw string tanggal dari API
    // Asumsi API kirim "2023-10-25T..." atau format database
    // Tapi di Kotlin kamu ada fungsi formatDate, di sini kita simpan hasil jadinya saja
    // Biar Provider yang ngurus formatting
    return AttendanceRecord(
      date: json['tgl_absen_formatted'] ?? json['tgl_absen'] ?? '', // Nanti di provider kita format ulang kalau perlu
      day: '', // Nanti diisi di provider
      clockIn: json['jam_masuk'] ?? '--:--',
      clockOut: json['jam_keluar'] ?? '--:--',
    );
  }
}