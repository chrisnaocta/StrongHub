import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stronghub/main.dart';
import '../services/firebase_realtime_service.dart';

import 'u_register.dart';
import 'a_login.dart';
import 'u_home.dart';
import 'a_dashboard.dart';

class LoginPageUser extends StatefulWidget {
  const LoginPageUser({super.key});

  @override
  State<LoginPageUser> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPageUser> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscureText = true;
  String _message = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();

    bool isLoginUser = prefs.getBool('isLoginUser') ?? false;
    bool isLoginAdmin = prefs.getBool('isLoginAdmin') ?? false;

    if (isLoginAdmin) {
      // Jika admin sudah login, arahkan ke Dashboard Admin
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPageAdmin()),
      );
    } else if (isLoginUser) {
      // Jika user sudah login, arahkan ke Dashboard User
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPageUser()),
      );
    }
  }

  /// 🔹 Proses login
  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _message = "Email dan password tidak boleh kosong.";
      });
      return;
    }

    setState(() {
      isLoading = true;
      _message = '';
    });

    final user = await FirebaseRealtimeService.loginUser(
      email: email,
      password: password,
    );

    setState(() => isLoading = false);

    if (user != null) {
      final role = user['role'] ?? 'user';

      if (role == 'admin') {
        setState(() {
          _message = "❌ Hanya user yang dapat login di sini.";
        });
        return;
      }

      // 🔹 Simpan status login ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoginUser', true);
      await prefs.setString('userEmail', email);
      String? userEmail = prefs.getString('userEmail');
      print("User email: $userEmail");

      bool? status = prefs.getBool('isLoginUser');
      print("DEBUG: isLoginUser diset jadi $status");

      // 🔹 Masuk ke dashboard user
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardPageUser()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login berhasil sebagai $role (${user['id']})')),
      );
    } else {
      setState(() {
        _message = "Email atau password salah.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // 🔸 Background gradien warna
          Container(
            width: screenWidth,
            height: screenHeight,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  redDark,
                  Colors.white,
                  Colors.white,
                  Colors.white,
                  grayMedium,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 🔹 Box Transparan
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 350,
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/StrongHub.png',
                          height: 140,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 28),

                        // 🔹 Input Email
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 🔹 Input Password
                        TextField(
                          controller: passwordController,
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // 🔹 Tombol Login
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: redPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            onPressed: isLoading ? null : _login,
                            child: isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 🔹 Pesan error
                        Text(
                          _message,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🔹 Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Belum punya akun?',
                        style: TextStyle(color: Colors.black87, fontSize: 15),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RegisterPageUser(),
                            ),
                          );
                        },
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 🔹 Admin Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Anda adalah Admin?',
                        style: TextStyle(color: Colors.red, fontSize: 15),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => LoginPageAdmin()),
                          );
                        },
                        child: const Text(
                          'Login sebagai admin',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
