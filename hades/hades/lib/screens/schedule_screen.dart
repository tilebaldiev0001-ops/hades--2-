import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int selectedDay = 0;

  final List<String> days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

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

  Future<void> toggleBooking(
      String classId,
      bool booked,
      bool hasActiveSub,
      ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (!booked && !hasActiveSub) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Для записи нужен действующий абонемент'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final ref = FirebaseFirestore.instance
        .collection('bookings')
        .doc('${uid}_$classId');

    try {
      if (booked) {
        await ref.delete();
      } else {
        await ref.set({
          'userId': uid,
          'classId': classId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось выполнить действие: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget noSubscriptionBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF3A1111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.red),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Нет действующего абонемента. Запись недоступна, обратитесь к администратору.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        automaticallyImplyLeading: false,
        title: const Text(
          'РАСПИСАНИЕ',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final active = index == selectedDay;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDay = index;
                      });
                    },
                    child: Container(
                      width: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? Colors.red : const Color(0xFF202020),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        days[index],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: active ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('subscriptions')
                    .doc(uid ?? '-')
                    .snapshots(),
                builder: (context, subSnap) {
                  final end =
                  (subSnap.data?.data()?['endDate'] as Timestamp?)
                      ?.toDate();
                  final hasActiveSub =
                      end != null && end.isAfter(DateTime.now());
                  final subLoaded = subSnap.hasData || subSnap.hasError;

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .where('userId', isEqualTo: uid)
                        .snapshots(),
                    builder: (context, bookingsSnap) {
                      if (bookingsSnap.hasError) {
                        return Center(
                          child: Text(
                            'Ошибка загрузки записей: ${bookingsSnap.error}',
                            style: const TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      final bookedIds = bookingsSnap.data?.docs
                          .map((d) => d.data()['classId'] as String)
                          .toSet() ??
                          <String>{};

                      return StreamBuilder<
                          QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('classes')
                            .where('dayOfWeek', isEqualTo: selectedDay)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Ошибка загрузки: ${snapshot.error}',
                                style: const TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting ||
                              !subLoaded) {
                            return const Center(
                              child:
                              CircularProgressIndicator(color: Colors.red),
                            );
                          }

                          final docs = snapshot.data?.docs.toList() ?? [];
                          docs.sort((a, b) =>
                              (a.data()['time'] as String? ?? '').compareTo(
                                  b.data()['time'] as String? ?? ''));

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!hasActiveSub) noSubscriptionBanner(),
                              Expanded(
                                child: docs.isEmpty
                                    ? const Center(
                                  child: Text(
                                    'В этот день тренировок нет',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                                    : ListView.builder(
                                  itemCount: docs.length,
                                  itemBuilder: (context, index) {
                                    final doc = docs[index];
                                    final item = doc.data();
                                    final booked =
                                    bookedIds.contains(doc.id);

                                    return Container(
                                      margin: const EdgeInsets.only(
                                          bottom: 12),
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF202020),
                                        borderRadius:
                                        BorderRadius.circular(15),
                                        border: booked
                                            ? Border.all(
                                            color: Colors.red,
                                            width: 1.5)
                                            : null,
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                iconFor(item['icon']
                                                as String?),
                                                color: Colors.red,
                                                size: 30,
                                              ),
                                              const SizedBox(width: 15),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                                  children: [
                                                    Text(
                                                      item['title']
                                                      as String? ??
                                                          '',
                                                      style:
                                                      const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                        FontWeight
                                                            .bold,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        height: 5),
                                                    Text(
                                                      item['time']
                                                      as String? ??
                                                          '',
                                                      style:
                                                      const TextStyle(
                                                          color: Colors
                                                              .grey),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 14),
                                          SizedBox(
                                            width: double.infinity,
                                            child: booked
                                                ? OutlinedButton(
                                              onPressed: () =>
                                                  toggleBooking(
                                                      doc.id,
                                                      true,
                                                      hasActiveSub),
                                              style: OutlinedButton
                                                  .styleFrom(
                                                foregroundColor:
                                                Colors.white,
                                                side: const BorderSide(
                                                    color:
                                                    Colors.red),
                                              ),
                                              child: const Text(
                                                  'ВЫ ЗАПИСАНЫ · ОТМЕНИТЬ'),
                                            )
                                                : ElevatedButton(
                                              onPressed: hasActiveSub
                                                  ? () =>
                                                  toggleBooking(
                                                      doc.id,
                                                      false,
                                                      hasActiveSub)
                                                  : null,
                                              style: ElevatedButton
                                                  .styleFrom(
                                                backgroundColor:
                                                Colors.red,
                                                foregroundColor:
                                                Colors.white,
                                                disabledBackgroundColor:
                                                const Color(
                                                    0xFF3A3A3A),
                                                disabledForegroundColor:
                                                Colors.grey,
                                              ),
                                              child: Text(
                                                hasActiveSub
                                                    ? 'ЗАПИСАТЬСЯ'
                                                    : 'НУЖЕН АБОНЕМЕНТ',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
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