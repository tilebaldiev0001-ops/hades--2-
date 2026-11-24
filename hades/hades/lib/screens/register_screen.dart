import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final surnameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool loading = false;

  @override
  void dispose() {
    nameController.dispose();
    surnameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE50914),
      ),
    );
  }

  Future<void> register() async {
    final name = nameController.text.trim();
    final surname = surnameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (name.isEmpty ||
        surname.isEmpty ||
        phone.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage('Заполни все поля');
      return;
    }

    if (password.length < 6) {
      showMessage('Пароль должен содержать минимум 6 символов');
      return;
    }

    if (password != confirmPassword) {
      showMessage('Пароли не совпадают');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final credential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName('$name $surname');

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String text = 'Не удалось зарегистрироваться. Попробуй ещё раз';

      if (e.code == 'email-already-in-use') {
        text = 'Эта почта уже зарегистрирована';
      } else if (e.code == 'invalid-email') {
        text = 'Неправильный формат почты';
      } else if (e.code == 'weak-password') {
        text = 'Слишком простой пароль';
      } else if (e.code == 'network-request-failed') {
        text = 'Нет соединения с интернетом';
      } else if (e.code == 'operation-not-allowed') {
        text = 'В Firebase не включён вход по почте и паролю';
      }

      showMessage(text);
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  InputDecoration inputDecoration(
      String hint,
      IconData icon, {
        Widget? suffix,
      }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.white54),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF1C1C1C),
      hintStyle: const TextStyle(color: Colors.white38),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.fitness_center,
                  size: 55,
                  color: Color(0xFFE50914),
                ),
                const SizedBox(height: 12),
                const Text(
                  'HADES',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'СОЗДАЙ СВОЙ АККАУНТ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration('Имя', Icons.person_outline),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: surnameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration('Фамилия', Icons.person_outline),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                  inputDecoration('Номер телефона', Icons.phone_outlined),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration(
                      'Электронная почта', Icons.email_outlined),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration(
                    'Пароль',
                    Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        hidePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white54,
                      ),
                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: hideConfirmPassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration(
                    'Повторите пароль',
                    Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        hideConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white54,
                      ),
                      onPressed: () {
                        setState(() {
                          hideConfirmPassword = !hideConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: loading ? null : register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE50914),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'ЗАРЕГИСТРИРОВАТЬСЯ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Уже есть аккаунт? Войти',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}