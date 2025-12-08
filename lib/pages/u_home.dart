import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stronghub/main.dart';
import '../services/firebase_realtime_service.dart';

import 'u_memberships.dart';
import 'u_status.dart';
import 'u_login.dart';

class DashboardPageUser extends StatefulWidget {
  const DashboardPageUser({super.key});

  @override
  State<DashboardPageUser> createState() => _DashboardPageUserState();
}

class _DashboardPageUserState extends State<DashboardPageUser> {
  String? userName;
  String? userEmail;
  String? userPhone;

  bool isLoading = true;
  List<Map<String, dynamic>> newsList = [];

  int _selectedIndex = 0;

  late final List<Widget Function()> _pages;

  @override
  void initState() {
    super.initState();
    _initUser();
    _loadNews();

    _pages = [
      () => _buildHomeNews(),
      () => const MembershipsPageUser(),
      () => const StatusPageUser(),
    ];
  }

  /// 🔹 Ambil user dari Firebase berdasarkan email tersimpan
  Future<void> _initUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('userEmail');

      if (email == null) return;

      final userData = await FirebaseRealtimeService.getUserDataByEmail(email);

      setState(() {
        userName = userData?['name'];
        userEmail = userData?['email'];
        userPhone = userData?['phone'];
      });
    } catch (e) {
      debugPrint("❌ Error init user: $e");
    }
  }

  /// 🔹 Logout user
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoginUser');
    await prefs.remove('userEmail');
    bool? status = prefs.getBool('isLoginUser');
    print("DEBUG: isLoginUser diset jadi $status");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPageUser()),
    );
  }

  /// 🔹 Ambil data news StrongHub dari Firebase
  Future<void> _loadNews() async {
    try {
      final data = await FirebaseRealtimeService.fetchNews();
      setState(() {
        newsList = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("❌ Error loading news: $e");
    }
  }

  /// 🔹 Drawer
  Drawer _buildDrawer() {
    return Drawer(
      backgroundColor: whiteColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: redDark),
            accountName: Text(userName ?? 'User'),
            accountEmail: Text(userEmail ?? '-'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: whiteColor,
              child: Text(
                (userName != null && userName!.isNotEmpty)
                    ? userName![0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: redDark,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.phone, color: redDark),
            title: Text(userPhone ?? 'Belum ada nomor telepon'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Keluar'),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  /// 🔹 HOME — daftar berita StrongHub
  Widget _buildHomeNews() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (newsList.isEmpty) {
      return const Center(
        child: Text(
          "Belum ada berita.",
          style: TextStyle(color: grayDark, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: newsList.length,
      itemBuilder: (context, index) {
        final news = newsList[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          color: whiteColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🏋️ Judul Berita
                Text(
                  news['title'] ?? "Tanpa Judul",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: blackPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                // 📄 Isi Berita
                Text(
                  news['content'] ?? "",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 12),

                // ⏱ Tanggal
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: grayMedium,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Dibuat pada: ${news['createdAt'] ?? '-'}",
                      style: const TextStyle(fontSize: 12, color: grayDark),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool showAppBar = _selectedIndex == 0;

    return Scaffold(
      backgroundColor: background,

      appBar: showAppBar
          ? AppBar(
              backgroundColor: redDark,
              centerTitle: true,
              title: Text(
                "Selamat datang, ${userName ?? ''}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: whiteColor,
                ),
              ),
            )
          : null,

      drawer: showAppBar ? _buildDrawer() : null,

      body: _pages[_selectedIndex](),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: redDark,
        unselectedItemColor: grayMedium,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_membership),
            label: "Membership",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.verified), label: "Status"),
        ],
      ),
    );
  }
}
