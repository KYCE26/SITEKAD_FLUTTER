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
  final String date;
  final String day;
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

  // Helper untuk parsing data dari API uHistori
  factory AttendanceRecord.fromApi(Map<String, dynamic> json) {
    // Logic parsing tanggal sederhana (bisa ditingkatkan dengan package intl)
    return AttendanceRecord(
      date: json['tgl_absen'] ?? '', // Format dari API backend
      day: '', // Nanti kita format di UI saja biar ringan
      clockIn: json['jam_masuk'] ?? '--:--',
      clockOut: json['jam_keluar'] ?? '--:--',
    );
  }
}