import 'package:cloud_firestore/cloud_firestore.dart';

// Заливает тестовые тренировки в Firestore, только если коллекция пустая.
// Безопасно вызывать при каждом запуске.

Future<void> seedClasses() async {
  final classes = FirebaseFirestore.instance.collection('classes');

  final existing = await classes.limit(1).get();
  if (existing.docs.isNotEmpty) return;

  // dayOfWeek: 0=Пн, 1=Вт, 2=Ср, 3=Чт, 4=Пт, 5=Сб, 6=Вс
  final data = [
    {'title': 'Силовая тренировка', 'time': '10:00 - 11:00', 'dayOfWeek': 0, 'icon': 'fitness_center'},
    {'title': 'Кардио', 'time': '18:00 - 19:00', 'dayOfWeek': 0, 'icon': 'directions_run'},
    {'title': 'Бокс', 'time': '12:00 - 13:00', 'dayOfWeek': 1, 'icon': 'sports_mma'},
    {'title': 'Силовая тренировка', 'time': '10:00 - 11:00', 'dayOfWeek': 2, 'icon': 'fitness_center'},
    {'title': 'Бокс', 'time': '19:00 - 20:00', 'dayOfWeek': 2, 'icon': 'sports_mma'},
    {'title': 'Кардио', 'time': '18:00 - 19:00', 'dayOfWeek': 3, 'icon': 'directions_run'},
    {'title': 'Силовая тренировка', 'time': '10:00 - 11:00', 'dayOfWeek': 4, 'icon': 'fitness_center'},
    {'title': 'Бокс', 'time': '12:00 - 13:00', 'dayOfWeek': 4, 'icon': 'sports_mma'},
    {'title': 'Кардио', 'time': '11:00 - 12:00', 'dayOfWeek': 5, 'icon': 'directions_run'},
  ];

  final batch = FirebaseFirestore.instance.batch();
  for (final item in data) {
    batch.set(classes.doc(), item);
  }
  await batch.commit();
}