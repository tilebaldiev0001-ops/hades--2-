import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin_users_screen.dart';
import 'admin_scan_screen.dart';
import 'admin_visits_screen.dart';

const List<String> adminDaysShort = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
const List<String> adminDaysFull = [
  'Понедельник',
  'Вторник',
  'Среда',
  'Четверг',
  'Пятница',
  'Суббота',
  'Воскресенье',
];

const Map<String, String> adminIcons = {
  'fitness_center': 'Силовая',
  'sports_mma': 'Бокс / единоборства',
  'directions_run': 'Кардио',
};

IconData adminIconFor(String? name) {
  switch (name) {
    case 'directions_run':
      return Icons.directions_run;
    case 'sports_mma':
      return Icons.sports_mma;
    case 'fitness_center':
    default:
      return Icons.fitness_center;
  }
}

/// Кнопка «Панель администратора». Показывается только админам.
class AdminButton extends StatelessWidget {
  const AdminButton({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
      FirebaseFirestore.instance.collection('admins').doc(uid).snapshots(),
      builder: (context, snap) {
        if (snap.hasError || !snap.hasData || !snap.data!.exists) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text(
                'ПАНЕЛЬ АДМИНИСТРАТОРА',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  Future<void> showClassDialog(
      BuildContext context, {
        String? docId,
        Map<String, dynamic>? data,
      }) async {
    final titleController =
    TextEditingController(text: data?['title'] as String? ?? '');
    final timeController =
    TextEditingController(text: data?['time'] as String? ?? '');
    int day = data?['dayOfWeek'] as int? ?? 0;
    String icon = data?['icon'] as String? ?? 'fitness_center';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF202020),
              title: Text(
                docId == null ? 'Новая тренировка' : 'Редактировать',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Название'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: timeController,
                      decoration: const InputDecoration(
                        labelText: 'Время',
                        hintText: '09:00 - 10:00',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: day,
                      dropdownColor: const Color(0xFF202020),
                      decoration:
                      const InputDecoration(labelText: 'День недели'),
                      items: [
                        for (int i = 0; i < 7; i++)
                          DropdownMenuItem(
                            value: i,
                            child: Text(adminDaysFull[i]),
                          ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => day = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: icon,
                      dropdownColor: const Color(0xFF202020),
                      decoration: const InputDecoration(labelText: 'Тип'),
                      items: adminIcons.entries
                          .map(
                            (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => icon = v);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final time = timeController.text.trim();
                    if (title.isEmpty || time.isEmpty) return;

                    final payload = {
                      'title': title,
                      'time': time,
                      'dayOfWeek': day,
                      'icon': icon,
                    };

                    try {
                      final col =
                      FirebaseFirestore.instance.collection('classes');
                      if (docId == null) {
                        await col.add(payload);
                      } else {
                        await col.doc(docId).update(payload);
                      }
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text('Не удалось сохранить: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Сохранить',
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

  Future<void> confirmDelete(
      BuildContext context,
      String docId,
      String title,
      ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF202020),
        title: const Text('Удалить тренировку?'),
        content: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final db = FirebaseFirestore.instance;

      // Сначала собираем все записи на эту тренировку
      final bookings = await db
          .collection('bookings')
          .where('classId', isEqualTo: docId)
          .get();

      // Удаляем записи и саму тренировку одной операцией
      final batch = db.batch();
      for (final b in bookings.docs) {
        batch.delete(b.reference);
      }
      batch.delete(db.collection('classes').doc(docId));
      await batch.commit();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось удалить: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('admins')
          .doc(uid ?? '-')
          .snapshots(),
      builder: (context, adminSnap) {
        final isAdmin = adminSnap.data?.exists ?? false;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF101010),
            title: const Text(
              'АДМИНИСТРАТОР',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
                color: Colors.red,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Посещения',
                icon: const Icon(Icons.history),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AdminVisitsScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Сканер',
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AdminScanScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Пользователи',
                icon: const Icon(Icons.people),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AdminUsersScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: isAdmin
              ? FloatingActionButton(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            onPressed: () => showClassDialog(context),
            child: const Icon(Icons.add),
          )
              : null,
          body: !adminSnap.hasData
              ? const Center(
            child: CircularProgressIndicator(color: Colors.red),
          )
              : !isAdmin
              ? const Center(
            child: Text(
              'Нет доступа',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          )
              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Text(
                    'Ошибка загрузки: ${snap.error}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              }
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.red,
                  ),
                );
              }

              final docs = snap.data!.docs.toList();
              docs.sort((a, b) {
                final byDay = (a.data()['dayOfWeek'] as int? ?? 0)
                    .compareTo(b.data()['dayOfWeek'] as int? ?? 0);
                if (byDay != 0) return byDay;
                return (a.data()['time'] as String? ?? '')
                    .compareTo(b.data()['time'] as String? ?? '');
              });

              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    'Тренировок нет. Нажмите «+», чтобы добавить.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final item = doc.data();
                  final dayIndex =
                  (item['dayOfWeek'] as int? ?? 0).clamp(0, 6);
                  final title = item['title'] as String? ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF202020),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          adminIconFor(item['icon'] as String?),
                          color: Colors.red,
                          size: 30,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${adminDaysShort[dayIndex]} · ${item['time'] ?? ''}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => showClassDialog(
                            context,
                            docId: doc.id,
                            data: item,
                          ),
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.grey,
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              confirmDelete(context, doc.id, title),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}