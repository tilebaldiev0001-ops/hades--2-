import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppNotification {
  final IconData icon;
  final String title;
  final String text;

  const AppNotification({
    required this.icon,
    required this.title,
    required this.text,
  });
}

/// Собирает список уведомлений из абонемента и записей пользователя.
class NotificationsBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, List<AppNotification> items)
  builder;

  const NotificationsBuilder({super.key, required this.builder});

  String formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return builder(context, const []);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(uid)
          .snapshots(),
      builder: (context, subSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('userId', isEqualTo: uid)
              .snapshots(),
          builder: (context, bookSnap) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream:
              FirebaseFirestore.instance.collection('classes').snapshots(),
              builder: (context, classSnap) {
                final items = <AppNotification>[];

                // Абонемент
                if (subSnap.hasData) {
                  final data = subSnap.data!.data();
                  final end = (data?['endDate'] as Timestamp?)?.toDate();

                  if (data == null || end == null) {
                    items.add(const AppNotification(
                      icon: Icons.card_membership,
                      title: 'Нет абонемента',
                      text: 'Оформите тариф во вкладке «Абонемент».',
                    ));
                  } else {
                    final remaining = end.difference(DateTime.now());
                    if (remaining.isNegative) {
                      items.add(AppNotification(
                        icon: Icons.warning_amber_rounded,
                        title: 'Абонемент истёк',
                        text: 'Срок закончился ${formatDate(end)}. Продлите его.',
                      ));
                    } else {
                      final daysLeft = (remaining.inHours / 24).ceil();
                      if (daysLeft <= 3) {
                        items.add(AppNotification(
                          icon: Icons.warning_amber_rounded,
                          title: 'Абонемент скоро закончится',
                          text: 'Осталось дней: $daysLeft '
                              '(до ${formatDate(end)}).',
                        ));
                      }
                    }
                  }
                }

                // Тренировки сегодня и завтра
                if (bookSnap.hasData && classSnap.hasData) {
                  final bookedIds = bookSnap.data!.docs
                      .map((d) => d.data()['classId'] as String)
                      .toSet();

                  final today = DateTime.now().weekday - 1; // 0 = Пн
                  final tomorrow = (today + 1) % 7;

                  final mine = classSnap.data!.docs
                      .where((d) => bookedIds.contains(d.id))
                      .map((d) => d.data())
                      .toList();

                  mine.sort((a, b) => (a['time'] as String? ?? '')
                      .compareTo(b['time'] as String? ?? ''));

                  for (final c in mine) {
                    final day = c['dayOfWeek'] as int? ?? -1;
                    final title = c['title'] as String? ?? '';
                    final time = c['time'] as String? ?? '';

                    if (day == today) {
                      items.add(AppNotification(
                        icon: Icons.fitness_center,
                        title: 'Сегодня: $title',
                        text: 'Время: $time',
                      ));
                    } else if (day == tomorrow) {
                      items.add(AppNotification(
                        icon: Icons.event,
                        title: 'Завтра: $title',
                        text: 'Время: $time',
                      ));
                    }
                  }
                }

                return builder(context, items);
              },
            );
          },
        );
      },
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        title: const Text(
          'УВЕДОМЛЕНИЯ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            color: Colors.red,
          ),
        ),
      ),
      body: NotificationsBuilder(
        builder: (context, items) {
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Новых уведомлений нет',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final n = items[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF202020),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Icon(n.icon, color: Colors.red, size: 30),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            n.text,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
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
  }
}