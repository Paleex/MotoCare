
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  List<dynamic> expenses = [];
  List<dynamic> motors = [];

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  final List<String> categories = [
    'BBM',
    'Servis',
    'Oli',
    'Spare Part',
    'Parkir',
    'Cuci Motor',
    'Lainnya',
  ];

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
        ApiService.getExpenses(),
        ApiService.getMotors(),
      ]);

      if (!mounted) return;

      setState(() {
        expenses = extractList(results[0]);
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

  String formatRupiah(num value) {
    final text = value.toInt().toString();
    final result = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      result.write(text[i]);

      final remaining = text.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        result.write('.');
      }
    }

    return 'Rp${result.toString()}';
  }

  String formatDate(dynamic value) {
    if (value == null) return '-';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String getMotorName(dynamic expense) {
    final motor = expense['motor_id'];

    if (motor is Map) {
      return '${motor['merk'] ?? ''} ${motor['model'] ?? ''}'.trim();
    }

    return 'Motor';
  }

  num get totalPengeluaran {
    num total = 0;

    for (final expense in expenses) {
      final value = expense['biaya'];

      if (value is num) {
        total += value;
      } else {
        total += num.tryParse(value.toString()) ?? 0;
      }
    }

    return total;
  }

  Future<void> showAddExpenseForm() async {
    if (motors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan data motor terlebih dahulu.'),
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final biayaController = TextEditingController();
    final keteranganController = TextEditingController();

    String? selectedMotorId;
    String selectedCategory = categories.first;
    DateTime selectedDate = DateTime.now();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Catatan Biaya'),
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
                          selectedMotorId = value;
                        },
                        validator: (value) =>
                            value == null ? 'Pilih motor' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                        ),
                        items: categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            selectedCategory = value;
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: biayaController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Biaya (Rp)',
                          hintText: 'Contoh: 50000',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final amount =
                              int.tryParse(value?.trim() ?? '');

                          if (amount == null || amount < 0) {
                            return 'Masukkan nominal yang valid';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Tanggal pengeluaran'),
                        subtitle: Text(
                          formatDate(selectedDate.toIso8601String()),
                        ),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );

                          if (date != null) {
                            setDialogState(() {
                              selectedDate = date;
                            });
                          }
                        },
                      ),
                      TextFormField(
                        controller: keteranganController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Keterangan (opsional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          if (selectedMotorId == null) return;

                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            await ApiService.addExpense(
                              motorId: selectedMotorId!,
                              kategori: selectedCategory,
                              tanggal:
                                  '${selectedDate.year}-'
                                  '${selectedDate.month.toString().padLeft(2, '0')}-'
                                  '${selectedDate.day.toString().padLeft(2, '0')}',
                              biaya: int.parse(
                                biayaController.text.trim(),
                              ),
                              keterangan:
                                  keteranganController.text.trim(),
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } catch (e) {
                            setDialogState(() {
                              saving = false;
                            });

                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Gagal menyimpan biaya: $e',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: saving
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

    biayaController.dispose();
    keteranganController.dispose();

    if (saved == true && mounted) {
      await loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan biaya berhasil ditambahkan'),
        ),
      );
    }
  }

  Future<void> deleteExpense(dynamic expense) async {
    final id = expense['_id']?.toString();
    if (id == null || id.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus catatan biaya?'),
        content: const Text(
          'Catatan yang dihapus tidak dapat dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteExpense(expenseId: id);
      await loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan biaya berhasil dihapus'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus catatan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Biaya'),
        actions: [
          IconButton(
            onPressed: loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading ? null : showAddExpenseForm,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Biaya'),
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
                        Text(
                          'Gagal memuat catatan biaya\n$errorMessage',
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
              : Column(
                  children: [
                    Card(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.account_balance_wallet),
                        ),
                        title: const Text('Total Pengeluaran'),
                        subtitle: const Text(
                          'Semua catatan biaya yang tersimpan',
                        ),
                        trailing: Text(
                          formatRupiah(totalPengeluaran),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: expenses.isEmpty
                          ? const Center(
                              child: Text(
                                'Belum ada catatan biaya.\n'
                                'Tekan Tambah Biaya untuk memulai.',
                                textAlign: TextAlign.center,
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: loadData,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16, 8, 16, 96,
                                ),
                                itemCount: expenses.length,
                                itemBuilder: (context, index) {
                                  final expense = expenses[index];

                                  return Card(
                                    margin: const EdgeInsets.only(
                                      bottom: 10,
                                    ),
                                    child: ListTile(
                                      leading: const CircleAvatar(
                                        child: Icon(Icons.receipt_long),
                                      ),
                                      title: Text(
                                        expense['kategori']?.toString()
                                            ?? 'Pengeluaran',
                                      ),
                                      subtitle: Text(
                                        '${getMotorName(expense)}\n'
                                        '${formatDate(expense['tanggal'])}'
                                        '${(expense['keterangan'] ?? '').toString().isNotEmpty ? '\n${expense['keterangan']}' : ''}',
                                      ),
                                      isThreeLine: true,
                                      trailing: SizedBox(
                                        width: 112,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                formatRupiah(
                                                  expense['biaya'] is num
                                                      ? expense['biaya']
                                                      : num.tryParse(
                                                            expense['biaya']
                                                                    ?.toString() ??
                                                                '',
                                                          ) ??
                                                          0,
                                                ),
                                                style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.end,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () =>
                                                  deleteExpense(expense),
                                              icon: const Icon(
                                                Icons.delete_outline,
                                              ),
                                              tooltip: 'Hapus catatan',
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}
