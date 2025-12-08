import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stronghub/main.dart';
import '../services/firebase_realtime_service.dart';

import 'a_register.dart';
import 'u_login.dart';
import 'a_dashboard.dart';
import 'u_home.dart';

class LoginPageAdmin extends StatefulWidget {
  const LoginPageAdmin({super.key});

  @override
  State<LoginPageAdmin> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPageAdmin> {
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

    if (isLoginUser) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPageUser()),
      );
    } else if (isLoginAdmin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPageAdmin()),
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

    final user = await FirebaseRealtimeService.loginAdmin(
      email: email,
      password: password,
    );

    setState(() => isLoading = false);

    if (user != null) {
      final role = user['role'] ?? 'user';

      if (role == 'user') {
        setState(() {
          _message = "❌ Hanya admin yang dapat login di sini.";
        });
        return;
      }

      // 🔹 Simpan status login ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoginAdmin', true);
      await prefs.setString('adminEmail', email);
      String? adminEmail = prefs.getString('adminEmail');
      print("Admin email: $adminEmail");

      bool? status = prefs.getBool('isLoginAdmin');
      print("DEBUG: isLoginAdmin diset jadi $status");

      // 🔹 Masuk ke dashboard admin
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardPageAdmin()),
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
                  orange, // hijau muda atas
                  Colors.white,
                  Colors.white,
                  Colors.white,
                  grayMedium, // biru bawah
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
                  // 🔸 Kotak transparan (card-like)
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
                        Text(
                          "ADMIN MODE",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        // 🔹 Logo tanpa frame
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
                              backgroundColor: orange,
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
                              builder: (_) => RegisterPageAdmin(),
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

                  // 🔹 Register sebagai admin
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Anda adalah User?',
                        style: TextStyle(color: yellow, fontSize: 15),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => LoginPageUser()),
                          );
                        },
                        child: const Text(
                          'Login sebagai user',
                          style: TextStyle(
                            color: yellow,
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
