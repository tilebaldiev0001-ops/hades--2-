import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String query = '';

  String formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }

  Future<void> grant(String uid, String plan, int days) async {
    final ref = FirebaseFirestore.instance.collection('subscriptions').doc(uid);
    final snap = await ref.get();

    final now = DateTime.now();
    DateTime start = now;
    DateTime base = now;

    // Если абонемент ещё действует, продлеваем от даты окончания
    if (snap.exists) {
      final data = snap.data()!;
      final end = (data['endDate'] as Timestamp?)?.toDate();
      final oldStart = (data['startDate'] as Timestamp?)?.toDate();
      if (end != null && end.isAfter(now)) {
        base = end;
        start = oldStart ?? now;
      }
    }

    await ref.set({
      'plan': plan,
      'startDate': Timestamp.fromDate(start),
      'endDate': Timestamp.fromDate(base.add(Duration(days: days))),
    });
  }

  Future<void> showUserDialog(String uid, String title) async {
    final messenger = ScaffoldMessenger.of(context);
    String plan = 'PREMIUM';
    int days = 30;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF202020),
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: plan,
                    dropdownColor: const Color(0xFF202020),
                    decoration: const InputDecoration(labelText: 'Тариф'),
                    items: const [
                      DropdownMenuItem(value: 'BASIC', child: Text('BASIC')),
                      DropdownMenuItem(
                          value: 'PREMIUM', child: Text('PREMIUM')),
                      DropdownMenuItem(value: 'VIP', child: Text('VIP')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => plan = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: days,
                    dropdownColor: const Color(0xFF202020),
                    decoration: const InputDecoration(labelText: 'Срок'),
                    items: const [
                      DropdownMenuItem(value: 30, child: Text('30 дней')),
                      DropdownMenuItem(value: 90, child: Text('90 дней')),
                      DropdownMenuItem(value: 180, child: Text('180 дней')),
                      DropdownMenuItem(value: 365, child: Text('365 дней')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => days = v);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    try {
                      await FirebaseFirestore.instance
                          .collection('subscriptions')
                          .doc(uid)
                          .delete();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Абонемент отозван'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Не удалось отозвать: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Отозвать',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    try {
                      await grant(uid, plan, days);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Выдан $plan на $days дн.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Не удалось выдать: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Выдать',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget subscriptionStatus(String uid) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(uid)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Text(
            'Ошибка загрузки',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          );
        }
        if (!snap.hasData) {
          return const Text(
            '...',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          );
        }

        final data = snap.data!.data();
        final end = (data?['endDate'] as Timestamp?)?.toDate();

        if (data == null || end == null) {
          return const Text(
            'Нет абонемента',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          );
        }

        final plan = data['plan'] as String? ?? '';
        final expired = end.isBefore(DateTime.now());

        return Text(
          expired
              ? '$plan · истёк ${formatDate(end)}'
              : '$plan · до ${formatDate(end)}',
          style: TextStyle(
            color: expired ? Colors.redAccent : Colors.greenAccent,
            fontSize: 13,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        title: const Text(
          'ПОЛЬЗОВАТЕЛИ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            color: Colors.red,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              onChanged: (v) => setState(() => query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Поиск по имени или почте',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFF202020),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream:
                FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(
                      child: Text(
                        'Ошибка загрузки: ${snap.error}',
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (!snap.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.red),
                    );
                  }

                  final docs = snap.data!.docs.where((d) {
                    final email =
                    (d.data()['email'] as String? ?? '').toLowerCase();
                    final name =
                    (d.data()['name'] as String? ?? '').toLowerCase();
                    return query.isEmpty ||
                        email.contains(query) ||
                        name.contains(query);
                  }).toList();

                  docs.sort((a, b) => (a.data()['email'] as String? ?? '')
                      .compareTo(b.data()['email'] as String? ?? ''));

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Никого не найдено.\nПользователь появляется в списке после входа в приложение.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final email = data['email'] as String? ?? '';
                      final name = data['name'] as String? ?? '';
                      final title = name.isNotEmpty ? name : email;

                      return GestureDetector(
                        onTap: () => showUserDialog(doc.id, title),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF202020),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Color(0xFF101010),
                                child: Icon(Icons.person, color: Colors.red),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (name.isNotEmpty)
                                      Text(
                                        email,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    subscriptionStatus(doc.id),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}