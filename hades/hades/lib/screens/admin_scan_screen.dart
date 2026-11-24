import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'my_qr_screen.dart';

class ScanResult {
  final bool ok;
  final String title;
  final String name;
  final String details;
  final String uid;
  final String plan;

  const ScanResult({
    required this.ok,
    required this.title,
    this.name = '',
    this.details = '',
    this.uid = '',
    this.plan = '',
  });
}

class AdminScanScreen extends StatefulWidget {
  const AdminScanScreen({super.key});

  @override
  State<AdminScanScreen> createState() => _AdminScanScreenState();
}

class _AdminScanScreenState extends State<AdminScanScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool busy = false;
  ScanResult? result;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }

  Future<ScanResult> check(String raw) async {
    if (!raw.startsWith(qrPrefix)) {
      return const ScanResult(ok: false, title: 'Это не QR клиента HADES');
    }
    final uid = raw.substring(qrPrefix.length);
    if (uid.isEmpty || uid.contains('/')) {
      return const ScanResult(ok: false, title: 'Некорректный QR-код');
    }

    final db = FirebaseFirestore.instance;
    final userSnap = await db.collection('users').doc(uid).get();
    if (!userSnap.exists) {
      return const ScanResult(ok: false, title: 'Клиент не найден');
    }

    final u = userSnap.data()!;
    final email = u['email'] as String? ?? '';
    final userName =
    (u['name'] as String? ?? '').isNotEmpty ? u['name'] as String : email;

    final subSnap = await db.collection('subscriptions').doc(uid).get();
    final sub = subSnap.data();
    final end = (sub?['endDate'] as Timestamp?)?.toDate();

    if (sub == null || end == null) {
      return ScanResult(
        ok: false,
        title: 'Нет абонемента',
        name: userName,
        details: email,
      );
    }

    final plan = sub['plan'] as String? ?? '';
    if (end.isBefore(DateTime.now())) {
      return ScanResult(
        ok: false,
        title: 'Абонемент истёк',
        name: userName,
        details: '$plan · истёк ${formatDate(end)}',
      );
    }

    return ScanResult(
      ok: true,
      title: 'Проходите',
      name: userName,
      details: '$plan · до ${formatDate(end)}',
      uid: uid,
      plan: plan,
    );
  }

  Future<void> saveVisit(ScanResult r) async {
    try {
      await FirebaseFirestore.instance.collection('visits').add({
        'userId': r.uid,
        'name': r.name,
        'plan': r.plan,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Не критично: клиент всё равно проходит
    }
  }

  Future<void> onDetect(BarcodeCapture capture) async {
    if (busy) return;
    if (capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    busy = true;
    ScanResult r;
    try {
      r = await check(raw);
    } catch (e) {
      r = ScanResult(ok: false, title: 'Ошибка проверки', details: '$e');
    }

    if (r.ok) {
      await saveVisit(r);
    }

    if (!mounted) return;
    setState(() => result = r);
  }

  void scanNext() {
    setState(() {
      result = null;
      busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = result;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        title: const Text(
          'СКАНЕР',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            color: Colors.red,
          ),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(controller: controller, onDetect: onDetect),
          if (r == null)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: Center(
                child: Text(
                  'Наведите камеру на QR клиента',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
            ),
          if (r != null)
            Positioned.fill(
              child: Container(
                color: r.ok ? Colors.green.shade800 : Colors.red.shade900,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      r.ok ? Icons.check_circle : Icons.cancel,
                      size: 90,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      r.title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (r.name.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        r.name,
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (r.details.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        r.details,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: scanNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'СКАНИРОВАТЬ СЛЕДУЮЩЕГО',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}