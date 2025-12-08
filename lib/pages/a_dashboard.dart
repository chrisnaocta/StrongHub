import 'package:flutter/material.dart';
import 'package:stronghub/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_realtime_service.dart';

import 'u_login.dart';

class DashboardPageAdmin extends StatefulWidget {
  const DashboardPageAdmin({super.key});

  @override
  State<DashboardPageAdmin> createState() => _DashboardPageAdminState();
}

class _DashboardPageAdminState extends State<DashboardPageAdmin> {
  String? userEmail = "";

  int destinationCount = 0;
  int userCount = 0;
  int bookingCount = 0;
  int reviewCount = 0;

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLogin = prefs.getBool('isLoginAdmin') ?? false;
    if (!isLogin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPageUser()),
      );
    } else {
      final email = prefs.getString('adminEmail');

      // 🔥 PENTING: pastikan UI rebuild setelah frame pertama selesai
      Future.microtask(() {
        setState(() {
          userEmail = email;
        });
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoginAdmin');
    await prefs.remove('userEmail');
    bool? status = prefs.getBool('isLoginUser');
    print("DEBUG: isLoginAdmin diset jadi $status");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPageUser()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: "Logout",
          ),
        ],
      ),
      body: const Center(
        child: Text("Dashboard Admin", style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
