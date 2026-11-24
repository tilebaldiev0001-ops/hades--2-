import 'package:flutter/material.dart';
import '../user_sync.dart';
import 'home_page.dart';
import 'schedule_screen.dart';
import 'subscription_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    HomePage(),
    ScheduleScreen(),
    SubscriptionScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    syncUserDoc();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF181818),
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'Расписание'),
          BottomNavigationBarItem(
              icon: Icon(Icons.card_membership), label: 'Абонемент'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }
}