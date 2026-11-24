import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyB0P3V14GsaHSuOpnriiNMLUeBd9hTGaVI',
      authDomain: 'hades-ebace.firebaseapp.com',
      projectId: 'hades-ebace',
      storageBucket: 'hades-ebace.firebasestorage.app',
      messagingSenderId: '898164408569',
      appId: '1:898164408569:web:b29d427a03e765e9cfa228',
    ),
  );

  runApp(const HadesApp());
}

class HadesApp extends StatelessWidget {
  const HadesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HADES',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF101010),
        primaryColor: Colors.red,
        colorScheme: const ColorScheme.dark(
          primary: Colors.red,
          secondary: Colors.redAccent,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.red),
              ),
            );
          }

          if (snapshot.hasData) {
            return const MainScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}