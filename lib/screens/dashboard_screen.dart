
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import 'motor_screen.dart';
import 'service_screen.dart';
import 'reminder_screen.dart';
import 'expense_screen.dart';
import 'statistics_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String userName = 'Pengguna';

  int jumlahMotor = 0;
  int jumlahServis = 0;
  int jumlahPengingat = 0;
  int totalPengeluaran = 0;

  bool isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  List<dynamic> extractList(dynamic response) {
  if (response is List) {
    return response;
  }

  if (response is Map) {
    final data = response['data'];

    if (data is List) {
      return data;
    }
  }

  throw Exception('Format data API tidak sesuai');
}

  Future<void> loadDashboard() async {
    try {
      final name = await StorageService.getUserName();
      final userId = await StorageService.getUserId();

      if (userId == null) {
        throw Exception('User ID tidak ditemukan. Silakan login ulang.');
      }

      final results = await Future.wait([
        ApiService.getMotors(),
        ApiService.getServices(),
        ApiService.getReminders(),
        ApiService.getExpenses(),
      ]);

      final List<dynamic> motors = extractList(results[0]);
      final List<dynamic> services = extractList(results[1]);
      final List<dynamic> reminders = extractList(results[2]);
      final List<dynamic> expenses = extractList(results[3]);

      final int pengingatAktif = reminders.where((reminder) {
        return reminder is Map && reminder['status']?.toString().toLowerCase() == 'aktif';
      }).length;

      int biaya = 0;

      for (final expense in expenses) {
        final value = expense['biaya'];
        biaya += value is num
            ? value.toInt()
            : int.tryParse(value.toString()) ?? 0;
      }

      if (!mounted) return;

      setState(() {
        userName = name ?? 'Pengguna';
        jumlahMotor = motors.length;
        jumlahServis = services.length;
        jumlahPengingat = pengingatAktif;
        totalPengeluaran = biaya;
        isLoadingStats = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingStats = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat statistik: $e'),
        ),
      );
    }
  }

  String formatRupiah(int value) {
    final text = value.toString();
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

  Future<void> bukaMotor() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MotorScreen(),
      ),
    );

    if (mounted) loadDashboard();
  }

  Future<void> bukaServis() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ServiceScreen(),
      ),
    );

    if (mounted) loadDashboard();
  }

  Future<void> bukaPengingat() async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ReminderScreen(),
    ),
  );

  if (mounted) loadDashboard();
}

  Future<void> bukaPengeluaran() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ExpenseScreen(),
      ),
    );

    if (mounted) loadDashboard();
  }

  Future<void> bukaStatistik() async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const StatisticsScreen(),
    ),
  );

  if (mounted) loadDashboard();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MotoCare',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: loadDashboard,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang statistik',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, $userName 👋',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Rawat motor kamu dengan lebih mudah.',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      Icons.two_wheeler,
                      'Motor',
                      isLoadingStats ? '...' : '$jumlahMotor',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      Icons.build,
                      'Servis',
                      isLoadingStats ? '...' : '$jumlahServis',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      Icons.notifications_active,
                      'Pengingat',
                      isLoadingStats ? '...' : '$jumlahPengingat',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      Icons.account_balance_wallet,
                      'Pengeluaran',
                      isLoadingStats ? '...' : formatRupiah(totalPengeluaran),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              const Text(
                'Menu MotoCare',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

              _buildMenu(
                Icons.two_wheeler,
                'Kelola Motor',
                'Tambah dan kelola data motor',
                onTap: bukaMotor,
              ),
              _buildMenu(
                Icons.build,
                'Riwayat Servis',
                'Lihat riwayat perawatan motor',
                onTap: bukaServis,
              ),
              _buildMenu(
                Icons.notifications_active,
                'Pengingat Servis',
                'Atur pengingat perawatan',
                onTap: bukaPengingat,
              ),
              _buildMenu(
                Icons.account_balance_wallet,
                'Catatan Biaya',
                'Catat pengeluaran motor',
                onTap: bukaPengeluaran,
              ),
              _buildMenu(
                Icons.bar_chart,
                'Statistik',
                'Lihat statistik perawatan',
                onTap: bukaStatistik,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 30, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 5),
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

  Widget _buildMenu(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
