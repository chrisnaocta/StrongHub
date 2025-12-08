import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stronghub/main.dart';
import '../services/firebase_realtime_service.dart';
import 'u_login.dart';
import 'u_home.dart';

class RegisterPageUser extends StatefulWidget {
  @override
  _RegisterPageUserState createState() => _RegisterPageUserState();
}

class _RegisterPageUserState extends State<RegisterPageUser> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscureText = true;
  String _message = '';
  bool isLoading = false;

  /// 🔹 Validasi input sebelum dikirim ke Firebase
  bool _validateInput({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) {
    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      setState(() => _message = "❌ Semua kolom wajib diisi.");
      return false;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _message = "❌ Format email tidak valid.");
      return false;
    }

    if (password.length < 6) {
      setState(() => _message = "❌ Password minimal 6 karakter.");
      return false;
    }

    if (phone.length < 9 || phone.length > 14) {
      setState(() => _message = "❌ Nomor HP tidak valid.");
      return false;
    }

    return true;
  }

  /// 🔹 Proses Register ke Firebase
  Future<void> _register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();

    if (!_validateInput(
      name: name,
      email: email,
      phone: phone,
      password: password,
    )) {
      return;
    }

    setState(() {
      isLoading = true;
      _message = '';
    });

    // 🔥 DAPATKAN UID HASIL REGISTER
    final userId = await FirebaseRealtimeService.registerUser(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );

    setState(() => isLoading = false);

    if (userId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoginUser', true);
      await prefs.setString('userEmail', email);
      await prefs.setString('userId', userId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Registrasi berhasil sebagai ($userId)!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardPageUser()),
      );
    } else {
      setState(() {
        _message = "❌ Gagal registrasi. Email mungkin sudah terdaftar.";
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
          // 🔸 Background gradasi
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

          // 🔹 Konten utama
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
                      color: Colors.white.withOpacity(0.85),
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
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "REGISTER USER",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 🔹 Input Nama
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Nama Lengkap',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 🔹 Input Nomor Telepon
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Nomor Telepon',
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 🔹 Input Email
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
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

                        // 🔹 Tombol Register
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            onPressed: isLoading ? null : _register,
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
                                    'Daftar Sekarang',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 🔹 Pesan error / status
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

                  // 🔹 Sudah punya akun
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sudah punya akun?',
                        style: TextStyle(color: Colors.black87, fontSize: 15),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPageUser(),
                            ),
                          );
                        },
                        child: const Text(
                          'Login di sini',
                          style: TextStyle(
                            color: Colors.black,
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
