
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<dynamic> expenses = [];
  List<dynamic> services = [];
  List<dynamic> motors = [];

  String selectedPeriod = 'Semua Waktu';
  final List<String> periods = [
    'Semua Waktu',
    'Bulan Ini',
    'Bulan Sebelumnya',
  ];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadStatistics();
  }

  List<dynamic> extractList(dynamic response) {
    if (response is List) return response;

    if (response is Map) {
      final data = response['data'];
      if (data is List) return data;
    }

    throw Exception('Format data API tidak sesuai');
  }

  Future<void> loadStatistics() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getExpenses(),
        ApiService.getServices(),
        ApiService.getMotors(),
      ]);

      if (!mounted) return;

      setState(() {
        expenses = extractList(results[0]);
        services = extractList(results[1]);
        motors = extractList(results[2]);
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

  num parseAmount(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
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

  String motorName(dynamic motor) {
    if (motor is! Map) return 'Motor tidak diketahui';

    final merk = motor['merk']?.toString() ?? '';
    final model = motor['model']?.toString() ?? '';
    final name = '$merk $model'.trim();

    return name.isEmpty ? 'Motor' : name;
  }


List<dynamic> get filteredServices {
  final now = DateTime.now();

  return services.where((service) {
    final date = DateTime.tryParse(
      service['tanggal']?.toString() ?? '',
    );

    if (date == null) return false;

    if (selectedPeriod == 'Bulan Ini') {
      return date.year == now.year &&
          date.month == now.month;
    }

    if (selectedPeriod == 'Bulan Sebelumnya') {
      final previousMonth = DateTime(now.year, now.month - 1);

      return date.year == previousMonth.year &&
          date.month == previousMonth.month;
    }

    return true;
  }).toList();
}

  
List<dynamic> get filteredExpenses {
  final now = DateTime.now();

  return expenses.where((expense) {
    final date = DateTime.tryParse(
      expense['tanggal']?.toString() ?? '',
    );

    if (date == null) return false;

    if (selectedPeriod == 'Bulan Ini') {
      return date.year == now.year && date.month == now.month;
    }

    if (selectedPeriod == 'Bulan Sebelumnya') {
      final previousMonth = DateTime(now.year, now.month - 1);

      return date.year == previousMonth.year &&
          date.month == previousMonth.month;
    }

    return true;
  }).toList();
}


  num get totalExpenses {
    return filteredExpenses.fold<num>(
      0,
      (total, expense) =>
          total + parseAmount(expense['biaya']),
    );
  }

  Map<String, num> get categoryTotals {
    final totals = <String, num>{};

    for (final expense in filteredExpenses) {
      final category =
          expense['kategori']?.toString() ?? 'Lainnya';

      totals[category] =
          (totals[category] ?? 0) +
          parseAmount(expense['biaya']);
    }

    return totals;
  }

  Map<String, num> get motorTotals {
    final totals = <String, num>{};

    for (final expense in filteredExpenses) {
      final motor = expense['motor_id'];
      final name = motorName(motor);

      totals[name] =
          (totals[name] ?? 0) +
          parseAmount(expense['biaya']);
    }

    return totals;
  }

  Widget buildSummaryCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.blue, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBreakdown(
    String title,
    Map<String, num> data,
  ) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxValue = entries.isEmpty
        ? 0.0
        : entries.first.value.toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              const Text('Belum ada data.')
            else
              ...entries.map((entry) {
                final fraction = maxValue <= 0
                    ? 0.0
                    : (entry.value.toDouble() / maxValue)
                        .clamp(0.0, 1.0)
                        .toDouble();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            formatRupiah(entry.value),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 9,
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

    
Map<DateTime, num> get monthlyExpenses {
  final totals = <DateTime, num>{};
  final now = DateTime.now();

  // Tampilkan enam bulan terakhir, termasuk bulan ini.
  for (int i = 5; i >= 0; i--) {
    final month = DateTime(now.year, now.month - i);
    totals[month] = 0;
  }

  for (final expense in expenses) {
    final date = DateTime.tryParse(
      expense['tanggal']?.toString() ?? '',
    );

    if (date == null) continue;

    final month = DateTime(date.year, date.month);

    if (totals.containsKey(month)) {
      totals[month] =
          (totals[month] ?? 0) +
          parseAmount(expense['biaya']);
    }
  }

  return totals;
}

String monthLabel(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  return '${months[date.month - 1]}\n${date.year}';
}

Widget buildMonthlyChart() {
  final data = monthlyExpenses.entries.toList();

  num maxValue = 0;
  for (final entry in data) {
    if (entry.value > maxValue) {
      maxValue = entry.value;
    }
  }

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pengeluaran Bulanan',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enam bulan terakhir',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 190,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((entry) {
                final fraction = maxValue == 0
                    ? 0.0
                    : (entry.value / maxValue)
                        .toDouble()
                        .clamp(0.0, 1.0);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          entry.value == 0
                              ? '-'
                              : formatRupiah(entry.value),
                          style: const TextStyle(fontSize: 9),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: fraction == 0
                                  ? 0.02
                                  : fraction,
                              widthFactor: 0.65,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius:
                                      BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          monthLabel(entry.key),
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik MotoCare'),
        actions: [
          IconButton(
            onPressed: loadStatistics,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang statistik',
          ),
        ],
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
                          'Gagal memuat statistik:\n$errorMessage',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: loadStatistics,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadStatistics,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Ringkasan Perawatan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedPeriod,
                        decoration: const InputDecoration(
                          labelText: 'Periode Pengeluaran',
                          border: OutlineInputBorder(),
                        ),
                        items: periods.map((period) {
                          return DropdownMenuItem<String>(
                            value: period,
                            child: Text(period),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            selectedPeriod = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 8),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.25,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        children: [
                          buildSummaryCard(
                            'Total Pengeluaran',
                            formatRupiah(totalExpenses),
                            Icons.account_balance_wallet,
                          ),
                          buildSummaryCard(
                            'Jumlah Servis',
                            '${filteredServices.length}',
                            Icons.build,
                          ),
                          buildSummaryCard(
                            'Jumlah Motor',
                            '${motors.length}',
                            Icons.two_wheeler,
                          ),
                          buildSummaryCard(
                            'Transaksi Biaya',
                            '${filteredExpenses.length}',
                            Icons.receipt_long,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      buildBreakdown(
                        'Pengeluaran per Kategori',
                        categoryTotals,
                      ),
                      const SizedBox(height: 12),
                      buildMonthlyChart(),
                      const SizedBox(height: 12),
                      buildBreakdown(
                        'Pengeluaran per Motor',
                        motorTotals,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Catatan: Total pengeluaran dihitung '
                        'dari Catatan Biaya. Jumlah servis '
                        'dihitung dari Riwayat Servis.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
