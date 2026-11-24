import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/subscription_card.dart';
import 'notifications_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const List<String> days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  IconData iconFor(String? name) {
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

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        automaticallyImplyLeading: false,
        title: const Text(
          'HADES',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            color: Colors.red,
          ),
        ),
        actions: [
          NotificationsBuilder(
            builder: (context, items) {
              return IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
                icon: Badge(
                  isLabelVisible: items.isNotEmpty,
                  label: Text('${items.length}'),
                  child: const Icon(Icons.notifications_none),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ПРИВЕТ, СПОРТСМЕН!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Стань сильнее.',
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),

            // Абонемент (данные из Firestore)
            const SubscriptionCard(),

            const SizedBox(height: 30),

            // Мои записи
            const Text(
              'МОИ ЗАПИСИ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 15),

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('userId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, bookingsSnap) {
                if (bookingsSnap.hasError) {
                  return Text(
                    'Ошибка загрузки записей: ${bookingsSnap.error}',
                    style: const TextStyle(color: Colors.grey),
                  );
                }

                final bookedIds = bookingsSnap.data?.docs
                    .map((d) => d.data()['classId'] as String)
                    .toSet() ??
                    <String>{};

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('classes')
                      .snapshots(),
                  builder: (context, classesSnap) {
                    if (classesSnap.hasError) {
                      return Text(
                        'Ошибка загрузки: ${classesSnap.error}',
                        style: const TextStyle(color: Colors.grey),
                      );
                    }

                    if (!classesSnap.hasData || !bookingsSnap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.red),
                        ),
                      );
                    }

                    final mine = classesSnap.data!.docs
                        .where((d) => bookedIds.contains(d.id))
                        .map((d) => d.data())
                        .toList();

                    mine.sort((a, b) {
                      final byDay = (a['dayOfWeek'] as int? ?? 0)
                          .compareTo(b['dayOfWeek'] as int? ?? 0);
                      if (byDay != 0) return byDay;
                      return (a['time'] as String? ?? '')
                          .compareTo(b['time'] as String? ?? '');
                    });

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (mine.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF202020),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Text(
                              'Вы пока никуда не записаны. Выберите тренировку во вкладке «Расписание».',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          ...mine.map(
                                (item) => workoutCard(
                              item['title'] as String? ?? '',
                              '${days[(item['dayOfWeek'] as int? ?? 0).clamp(0, 6)]}, ${item['time'] ?? ''}',
                              iconFor(item['icon'] as String?),
                            ),
                          ),

                        const SizedBox(height: 25),

                        // Активность
                        const Text(
                          'ТВОЯ АКТИВНОСТЬ',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 15),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF202020),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.local_fire_department,
                                color: Colors.red,
                                size: 40,
                              ),
                              const SizedBox(width: 15),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Записей на неделю: ${mine.length}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Тренировок в вашем расписании',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Карточка тренировки
  Widget workoutCard(
      String title,
      String time,
      IconData icon,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.red,
            size: 30,
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
                const SizedBox(height: 5),
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}