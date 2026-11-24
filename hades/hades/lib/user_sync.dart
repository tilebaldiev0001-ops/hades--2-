import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Сохраняет почту и имя текущего пользователя в коллекцию users,
/// чтобы администратор мог найти его в списке.
Future<void> syncUserDoc() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'email': user.email ?? '',
      'name': user.displayName ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  } catch (_) {
    // Не критично: если не получилось, попробуем при следующем входе
  }
}