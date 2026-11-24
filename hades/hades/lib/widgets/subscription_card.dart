import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SubscriptionCard extends StatelessWidget {
  final String title;

  const SubscriptionCard({super.key, this.title = 'ТВОЙ АБОНЕМЕНТ'});

  String formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(uid)
          .snapshots(),
      builder: (context, snap) {
        Widget content;

        if (snap.hasError) {
          content = Text(
            'Ошибка загрузки: ${snap.error}',
            style: const TextStyle(color: Colors.white70),
          );
        } else if (!snap.hasData) {
          content = const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        } else {
          final data = snap.data!.data();
          final plan = data?['plan'] as String? ?? '';
          final end = (data?['endDate'] as Timestamp?)?.toDate();
          final start = (data?['startDate'] as Timestamp?)?.toDate();

          if (data == null || end == null) {
            content = const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12),
                Text(
                  'Абонемента нет',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Выберите тариф во вкладке «Абонемент»',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            );
          } else {
            final now = DateTime.now();
            final remaining = end.difference(now);
            final expired = remaining.isNegative;
            final daysLeft = expired ? 0 : (remaining.inHours / 24).ceil();

            double progress = 0;
            if (!expired && start != null) {
              final total = end.difference(start).inHours;
              if (total > 0) {
                progress = (remaining.inHours / total).clamp(0.0, 1.0);
              }
            }

            content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  plan,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  expired
                      ? 'Истёк ${formatDate(end)}'
                      : 'Действует до ${formatDate(end)}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.black38,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  expired ? 'Нужно продлить' : 'Осталось дней: $daysLeft',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            );
          }
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B0000), Color(0xFF330000)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white70, letterSpacing: 2),
              ),
              content,
            ],
          ),
        );
      },
    );
  }
}