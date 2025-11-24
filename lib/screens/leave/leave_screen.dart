import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _descriptionController = TextEditingController();
  
  // State Variables
  String? _selectedReason;
  DateTime? _startDate;
  DateTime? _endDate;
  File? _suketFile;
  bool _isLoading = false;

  final List<String> _reasonList = [
    "Sakit",
    "Cuti Tahunan",
    "Keperluan Mendesak",
    "Lainnya"
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _suketFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Reset end date jika start date melebihi end date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi Tanggal
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mohon pilih tanggal mulai dan selesai")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = Provider.of<UserProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Format Tanggal ke String (yyyy-MM-dd) sesuai spec API
    final startStr = DateFormat('yyyy-MM-dd').format(_startDate!);
    final endStr = DateFormat('yyyy-MM-dd').format(_endDate!);

    final success = await provider.submitCuti(
      alasan: _selectedReason!,
      startDate: startStr,
      endDate: endStr,
      description: _descriptionController.text,
      suketFile: _suketFile,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Pengajuan Cuti Berhasil!"), backgroundColor: Colors.green),
      );
      navigator.pop(); // Kembali ke Home
    } else if (mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Gagal mengajukan cuti."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Pengajuan Cuti")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. PILIH ALASAN (DIPERBAIKI)
              DropdownButtonFormField<String>(
                // PERBAIKAN: Ganti 'value' menjadi 'initialValue'
                initialValue: _selectedReason,
                items: _reasonList.map((reason) {
                  return DropdownMenuItem(value: reason, child: Text(reason));
                }).toList(),
                onChanged: (val) => setState(() => _selectedReason = val),
                decoration: const InputDecoration(
                  labelText: "Alasan Cuti *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (val) => val == null ? "Wajib dipilih" : null,
              ),
              const SizedBox(height: 16),

              // 2. PILIH TANGGAL
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: "Tanggal Mulai *",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _startDate == null ? "Pilih" : DateFormat('dd MMM yyyy').format(_startDate!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: "Tanggal Selesai *",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event),
                        ),
                        child: Text(
                          _endDate == null ? "Pilih" : DateFormat('dd MMM yyyy').format(_endDate!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. KETERANGAN
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Keterangan (Opsional)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // 4. UPLOAD FILE (OPSIONAL)
              const Text("Lampiran (Surat Dokter/Lainnya)", style: TextStyle(fontWeight: FontWeight.bold)),
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
                    image: _suketFile != null 
                        ? DecorationImage(image: FileImage(_suketFile!), fit: BoxFit.cover)
                        : null
                  ),
                  child: _suketFile == null 
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.attach_file, size: 40, color: Colors.grey),
                            Text("Tap untuk upload foto", style: TextStyle(color: Colors.grey)),
                          ],
                        ) 
                      : null,
                ),
              ),
              if (_suketFile != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _suketFile = null),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text("Hapus Lampiran", style: TextStyle(color: Colors.red)),
                  ),
                ),

              const SizedBox(height: 32),

              // 5. TOMBOL SUBMIT
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("AJUKAN CUTI", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}