
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MotorScreen extends StatefulWidget {
  const MotorScreen({super.key});

  @override
  State<MotorScreen> createState() => _MotorScreenState();
}

class _MotorScreenState extends State<MotorScreen> {
  List<dynamic> motors = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMotors();
  }

  Future<void> loadMotors() async {
    try {
      final result = await ApiService.getMotors();
      dynamic data = result;

      if (data is Map<String, dynamic>) {
        data = data['data'] ?? data['motors'];
      }

      if (data is! List) {
        throw Exception('Format respons API tidak sesuai.');
      }

      if (!mounted) return;

      setState(() {
        motors = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data motor: $e')),
      );
    }
  }

  Future<void> openAddMotorForm() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddMotorScreen(),
      ),
    );

    if (added == true) {
      setState(() => isLoading = true);
      await loadMotors();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kelola Motor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : motors.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: loadMotors,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: motors.length,
                    itemBuilder: (context, index) {
                      return _buildMotorCard(motors[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddMotorForm,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Motor'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.two_wheeler,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum ada motor',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tambahkan motor kamu untuk mulai menggunakan MotoCare.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: openAddMotorForm,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Motor'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotorCard(dynamic motor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.two_wheeler),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${motor['merk'] ?? ''} ${motor['model'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text('Plat Nomor: ${motor['plat_nomor'] ?? '-'}'),
            const SizedBox(height: 5),
            Text('Tahun: ${motor['tahun'] ?? '-'}'),
            const SizedBox(height: 5),
            Text('CC: ${motor['cc'] ?? '-'} cc'),
            const SizedBox(height: 5),
            Text('Kilometer: ${motor['kilometer'] ?? 0} km'),
          ],
        ),
      ),
    );
  }
}

class AddMotorScreen extends StatefulWidget {
  const AddMotorScreen({super.key});

  @override
  State<AddMotorScreen> createState() => _AddMotorScreenState();
}

class _AddMotorScreenState extends State<AddMotorScreen> {
  final _formKey = GlobalKey<FormState>();

  final merkController = TextEditingController();
  final modelController = TextEditingController();
  final tahunController = TextEditingController();
  final ccController = TextEditingController();
  final platController = TextEditingController();
  final kilometerController = TextEditingController(text: '0');

  bool isSaving = false;

  @override
  void dispose() {
    merkController.dispose();
    modelController.dispose();
    tahunController.dispose();
    ccController.dispose();
    platController.dispose();
    kilometerController.dispose();
    super.dispose();
  }

  String? requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label wajib diisi';
    }
    return null;
  }

  String? requiredNumber(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label wajib diisi';
    }

    if (int.tryParse(value.trim()) == null) {
      return '$label harus berupa angka bulat';
    }

    if (int.parse(value.trim()) < 0) {
      return '$label tidak boleh negatif';
    }

    return null;
  }

  Future<void> saveMotor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      final result = await ApiService.addMotor({
        'merk': merkController.text.trim(),
        'model': modelController.text.trim(),
        'tahun': int.parse(tahunController.text.trim()),
        'cc': int.parse(ccController.text.trim()),
        'plat_nomor': platController.text.trim(),
        'kilometer': int.parse(kilometerController.text.trim()),
      });

      if (!mounted) return;

      if (result is Map && result['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Motor berhasil ditambahkan'),
          ),
        );
        Navigator.pop(context, true);
      } else {
        final message = result is Map
            ? result['message']?.toString() ?? 'Gagal menambahkan motor'
            : 'Respons server tidak sesuai';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan motor: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Widget buildField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tambah Motor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(
                Icons.two_wheeler,
                size: 64,
                color: Colors.blue,
              ),
              const SizedBox(height: 8),
              const Text(
                'Informasi Motor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              buildField(
                label: 'Merek Motor',
                controller: merkController,
                validator: (v) => requiredText(v, 'Merek motor'),
                hint: 'Contoh: Honda',
              ),
              buildField(
                label: 'Model Motor',
                controller: modelController,
                validator: (v) => requiredText(v, 'Model motor'),
                hint: 'Contoh: Beat',
              ),
              buildField(
                label: 'Tahun',
                controller: tahunController,
                validator: (v) => requiredNumber(v, 'Tahun'),
                keyboardType: TextInputType.number,
                hint: 'Contoh: 2015',
              ),
              buildField(
                label: 'Kapasitas Mesin (CC)',
                controller: ccController,
                validator: (v) => requiredNumber(v, 'CC'),
                keyboardType: TextInputType.number,
                hint: 'Contoh: 110',
              ),
              buildField(
                label: 'Plat Nomor',
                controller: platController,
                validator: (v) => requiredText(v, 'Plat nomor'),
                hint: 'Contoh: B 1234 XYZ',
              ),
              buildField(
                label: 'Kilometer',
                controller: kilometerController,
                validator: (v) => requiredNumber(v, 'Kilometer'),
                keyboardType: TextInputType.number,
                hint: 'Contoh: 15000',
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : saveMotor,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    isSaving ? 'Menyimpan...' : 'Simpan Motor',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
