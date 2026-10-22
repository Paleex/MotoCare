
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  List<dynamic> services = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadServices();
  }

  Future<void> loadServices() async {
    try {
      final result = await ApiService.getServices();
      dynamic data = result;

      if (data is Map<String, dynamic>) {
        data = data['data'] ?? data['services'];
      }

      if (data is! List) {
        throw Exception('Format respons riwayat servis tidak sesuai.');
      }

      if (!mounted) return;

      setState(() {
        services = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat riwayat servis: $e')),
      );
    }
  }

  Future<void> openAddForm() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddServiceScreen(),
      ),
    );

    if (added == true) {
      setState(() => isLoading = true);
      await loadServices();
    }
  }

  String formatDate(dynamic value) {
    if (value == null) return '-';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String formatRupiah(dynamic value) {
    final amount = int.tryParse(value.toString()) ?? 0;
    final digits = amount.toString();
    final formatted = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );

    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Servis',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : services.isEmpty
              ? buildEmptyState()
              : RefreshIndicator(
                  onRefresh: loadServices,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      return buildServiceCard(services[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddForm,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Servis'),
      ),
    );
  }

  Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.build_circle_outlined,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Riwayat Servis',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Catat servis motor kamu agar riwayat perawatan tersimpan.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: openAddForm,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Servis'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildServiceCard(dynamic service) {
    final motor = service['motor_id'];
    final motorName = motor is Map
        ? '${motor['merk'] ?? ''} ${motor['model'] ?? ''}'.trim()
        : 'Motor';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.build),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    service['jenis_servis']?.toString() ?? 'Servis',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Motor: $motorName'),
            const SizedBox(height: 5),
            Text('Tanggal: ${formatDate(service['tanggal_servis'])}'),
            const SizedBox(height: 5),
            Text('Kilometer: ${service['kilometer'] ?? 0} km'),
            const SizedBox(height: 5),
            Text(
              'Biaya: ${formatRupiah(service['biaya'])}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if ((service['catatan'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 5),
              Text('Catatan: ${service['catatan']}'),
            ],
          ],
        ),
      ),
    );
  }
}

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final formKey = GlobalKey<FormState>();

  final jenisController = TextEditingController();
  final kilometerController = TextEditingController();
  final biayaController = TextEditingController();
  final catatanController = TextEditingController();

  List<dynamic> motors = [];
  String? selectedMotorId;
  DateTime selectedDate = DateTime.now();
  bool isLoadingMotors = true;
  bool isSaving = false;
  String? loadError;

  @override
  void initState() {
    super.initState();
    loadMotors();
  }

  @override
  void dispose() {
    jenisController.dispose();
    kilometerController.dispose();
    biayaController.dispose();
    catatanController.dispose();
    super.dispose();
  }

  Future<void> loadMotors() async {
    try {
      final result = await ApiService.getMotors();
      dynamic data = result;

      if (data is Map<String, dynamic>) {
        data = data['data'] ?? data['motors'];
      }

      if (data is! List) {
        throw Exception('Format daftar motor tidak sesuai.');
      }

      if (!mounted) return;

      setState(() {
        motors = data;
        isLoadingMotors = false;
        loadError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingMotors = false;
        loadError = e.toString();
      });
    }
  }

  String? validateText(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label wajib diisi';
    }
    return null;
  }

  String? validateNumber(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label wajib diisi';
    }

    final number = int.tryParse(value.trim());

    if (number == null || number < 0) {
      return '$label harus berupa angka nol atau lebih';
    }

    return null;
  }

  Future<void> chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (date != null && mounted) {
      setState(() => selectedDate = date);
    }
  }

  Future<void> saveService() async {
    if (!formKey.currentState!.validate()) return;

    if (selectedMotorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih motor terlebih dahulu')),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final result = await ApiService.addService({
        'motor_id': selectedMotorId,
        'tanggal_servis':
            '${selectedDate.year}-'
            '${selectedDate.month.toString().padLeft(2, '0')}-'
            '${selectedDate.day.toString().padLeft(2, '0')}',
        'jenis_servis': jenisController.text.trim(),
        'kilometer': int.parse(kilometerController.text.trim()),
        'biaya': int.parse(biayaController.text.trim()),
        'catatan': catatanController.text.trim(),
      });

      if (!mounted) return;

      if (result is Map && result['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Riwayat servis berhasil disimpan'),
          ),
        );
        Navigator.pop(context, true);
      } else {
        final message = result is Map
            ? result['message']?.toString() ?? 'Gagal menyimpan servis'
            : 'Respons server tidak sesuai';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan servis: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Widget textField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
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
          'Tambah Riwayat Servis',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoadingMotors
          ? const Center(child: CircularProgressIndicator())
          : loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Gagal memuat motor:\n$loadError',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => isLoadingMotors = true);
                            loadMotors();
                          },
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : motors.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Kamu belum memiliki motor. Tambahkan motor '
                          'terlebih dahulu di halaman Kelola Motor.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Form(
                      key: formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          DropdownButtonFormField<String>(
                            value: selectedMotorId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Pilih Motor',
                              border: OutlineInputBorder(),
                            ),
                            items: motors.map<DropdownMenuItem<String>>(
                              (motor) {
                                return DropdownMenuItem<String>(
                                  value: motor['_id']?.toString(),
                                  child: Text(
                                    '${motor['merk'] ?? ''} '
                                    '${motor['model'] ?? ''} '
                                    '(${motor['plat_nomor'] ?? '-'})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ).where((item) => item.value != null).toList(),
                            onChanged: (value) {
                              setState(() => selectedMotorId = value);
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Pilih motor terlebih dahulu';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          textField(
                            label: 'Jenis Servis',
                            controller: jenisController,
                            validator: (v) => validateText(v, 'Jenis servis'),
                          ),
                          InkWell(
                            onTap: chooseDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Tanggal Servis',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_month),
                              ),
                              child: Text(
                                '${selectedDate.day.toString().padLeft(2, '0')}/'
                                '${selectedDate.month.toString().padLeft(2, '0')}/'
                                '${selectedDate.year}',
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          textField(
                            label: 'Kilometer Saat Servis',
                            controller: kilometerController,
                            validator: (v) => validateNumber(v, 'Kilometer'),
                            keyboardType: TextInputType.number,
                          ),
                          textField(
                            label: 'Biaya Servis (Rupiah)',
                            controller: biayaController,
                            validator: (v) => validateNumber(v, 'Biaya'),
                            keyboardType: TextInputType.number,
                          ),
                          textField(
                            label: 'Catatan (Opsional)',
                            controller: catatanController,
                            validator: (_) => null,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: isSaving ? null : saveService,
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
                                isSaving ? 'Menyimpan...' : 'Simpan Servis',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
