import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'login_screen.dart';
import 'admin_screen.dart';
import 'my_qr_screen.dart';
import '../user_sync.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool uploadingAvatar = false;

  String formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }

  Widget infoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.red),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> pickAvatar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || uploadingAvatar) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 70,
      );
      if (picked == null) return;

      setState(() => uploadingAvatar = true);

      final bytes = await picked.readAsBytes();
      final b64 = base64Encode(bytes);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'avatar': b64,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось сохранить фото: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => uploadingAvatar = false);
    }
  }

  Widget avatarWidget(String uid) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
      FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        final b64 = snap.data?.data()?['avatar'] as String?;
        ImageProvider? image;
        if (b64 != null && b64.isNotEmpty) {
          try {
            image = MemoryImage(base64Decode(b64));
          } catch (_) {
            image = null;
          }
        }

        return GestureDetector(
          onTap: pickAvatar,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFF202020),
                backgroundImage: image,
                child: uploadingAvatar
                    ? const CircularProgressIndicator(color: Colors.red)
                    : (image == null
                    ? const Icon(Icons.person, size: 55, color: Colors.red)
                    : null),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> editName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final controller = TextEditingController(text: user.displayName ?? '');

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF202020),
        title: const Text('Ваше имя'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Введите имя'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text(
              'Сохранить',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty) return;

    try {
      await user.updateDisplayName(newName);
      await user.reload();
      await syncUserDoc();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось сохранить имя: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Вы не авторизованы')),
      );
    }

    final name = (user.displayName != null && user.displayName!.isNotEmpty)
        ? user.displayName!
        : 'Спортсмен';
    final email = user.email ?? '—';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        automaticallyImplyLeading: false,
        title: const Text(
          'ПРОФИЛЬ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            color: Colors.red,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            avatarWidget(user.uid),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: editName,
                  icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),
            infoRow(Icons.email, 'Почта', email),
            const AdminButton(),
            const MyQrButton(),

            // Абонемент из Firestore
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('subscriptions')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snap) {
                String value = 'Загрузка...';

                if (snap.hasError) {
                  value = 'Ошибка загрузки';
                } else if (snap.hasData) {
                  final data = snap.data!.data();
                  final end = (data?['endDate'] as Timestamp?)?.toDate();

                  if (data == null || end == null) {
                    value = 'Нет абонемента';
                  } else {
                    final plan = data['plan'] as String? ?? '';
                    value = end.isBefore(DateTime.now())
                        ? '$plan · истёк ${formatDate(end)}'
                        : '$plan · до ${formatDate(end)}';
                  }
                }

                return infoRow(Icons.card_membership, 'Абонемент', value);
              },
            ),

            // Количество записей
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snap) {
                String value = 'Загрузка...';

                if (snap.hasError) {
                  value = 'Ошибка загрузки';
                } else if (snap.hasData) {
                  value = '${snap.data!.docs.length}';
                }

                return infoRow(
                  Icons.event_available,
                  'Записей на тренировки',
                  value,
                );
              },
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await FirebaseAuth.instance.signOut();
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                        (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'ВЫЙТИ',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}