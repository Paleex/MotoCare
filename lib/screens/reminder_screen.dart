
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  List<dynamic> reminders = [];
  List<dynamic> motors = [];
  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  List<dynamic> extractList(dynamic response) {
    if (response is List) return response;

    if (response is Map) {
      final data = response['data'];
      if (data is List) return data;
    }

    throw Exception('Format data API tidak sesuai');
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getReminders(),
        ApiService.getMotors(),
      ]);

      if (!mounted) return;

      setState(() {
        reminders = extractList(results[0]);
        motors = extractList(results[1]);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  String motorName(dynamic reminder) {
    final motor = reminder is Map ? reminder['motor_id'] : null;

    if (motor is Map) {
      return '${motor['merk'] ?? ''} ${motor['model'] ?? ''}'.trim();
    }

    return 'Motor';
  }

  String formatDate(dynamic value) {
    if (value == null) return '-';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();

    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  Future<void> showAddReminderForm() async {
    if (motors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan data motor terlebih dahulu.'),
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final jenisController = TextEditingController();
    final kmController = TextEditingController();
    final catatanController = TextEditingController();

    String? selectedMotorId;
    DateTime selectedDate = DateTime.now().add(
      const Duration(days: 30),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Pengingat Servis'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                            final id = motor['_id'].toString();
                            final name =
                                '${motor['merk'] ?? ''} '
                                '${motor['model'] ?? ''}'.trim();

                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text(
                                name.isEmpty ? 'Motor' : name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedMotorId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Pilih motor terlebih dahulu';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: jenisController,
                        decoration: const InputDecoration(
                          labelText: 'Jenis Servis',
                          hintText: 'Contoh: Ganti Oli',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Jenis servis wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Tanggal jatuh tempo: '
                          '${formatDate(selectedDate.toIso8601String())}',
                        ),
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );

                          if (date != null) {
                            setDialogState(() {
                              selectedDate = date;
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('Pilih Tanggal'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: kmController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Target Kilometer (opsional)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value != null &&
                              value.trim().isNotEmpty) {
                            final km = int.tryParse(value.trim());
                            if (km == null || km < 0) {
                              return 'Masukkan kilometer yang valid';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: catatanController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (opsional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          if (selectedMotorId == null) return;

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            await ApiService.addReminder(
                              motorId: selectedMotorId!,
                              jenisServis: jenisController.text.trim(),
                              tanggalJatuhTempo:
                                  '${selectedDate.year}-'
                                  '${selectedDate.month.toString().padLeft(2, '0')}-'
                                  '${selectedDate.day.toString().padLeft(2, '0')}',
                              kilometerTarget:
                                  kmController.text.trim().isEmpty
                                      ? null
                                      : int.parse(kmController.text.trim()),
                              catatan: catatanController.text.trim(),
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                            });

                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text('Gagal menyimpan: $e'),
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    jenisController.dispose();
    kmController.dispose();
    catatanController.dispose();

    if (saved == true && mounted) {
      await loadData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengingat berhasil ditambahkan'),
        ),
      );
    }
  }

  Future<void> markAsDone(dynamic reminder) async {
    final id = reminder['_id']?.toString();
    if (id == null || id.isEmpty) return;

    try {
      await ApiService.updateReminderStatus(
        reminderId: id,
        status: 'selesai',
      );

      await loadData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengingat ditandai selesai'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui pengingat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengingat Servis'),
        actions: [
          IconButton(
            onPressed: loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading ? null : showAddReminderForm,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Pengingat'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Gagal memuat pengingat servis',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: loadData,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : reminders.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Belum ada pengingat servis',
                              style: TextStyle(fontSize: 18),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Tekan Tambah Pengingat untuk memulai.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          16, 16, 16, 96,
                        ),
                        itemCount: reminders.length,
                        itemBuilder: (context, index) {
                          final reminder = reminders[index];
                          final status =
                              reminder['status']?.toString() ?? 'aktif';
                          final isDone = status == 'selesai';
                          final km = reminder['kilometer_target'];
                          final motor = reminder['motor_id'];
                          final plat = motor is Map
                              ? motor['plat_nomor']?.toString()
                              : null;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        child: Icon(
                                          isDone
                                              ? Icons.check
                                              : Icons.build,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              reminder['jenis_servis']
                                                      ?.toString() ??
                                                  'Servis',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                            Text(motorName(reminder)),
                                            if (plat != null &&
                                                plat.isNotEmpty)
                                              Text('Plat: $plat'),
                                          ],
                                        ),
                                      ),
                                      Chip(
                                        label: Text(
                                          isDone ? 'Selesai' : 'Aktif',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Jatuh tempo: '
                                          '${formatDate(reminder['tanggal_jatuh_tempo'])}',
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (km != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.speed,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text('Target: $km km'),
                                      ],
                                    ),
                                  ],
                                  if ((reminder['catatan'] ?? '')
                                      .toString()
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Catatan: ${reminder['catatan']}',
                                    ),
                                  ],
                                  if (!isDone) ...[
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () =>
                                            markAsDone(reminder),
                                        icon: const Icon(
                                          Icons.check_circle_outline,
                                        ),
                                        label: const Text(
                                          'Tandai Selesai',
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
