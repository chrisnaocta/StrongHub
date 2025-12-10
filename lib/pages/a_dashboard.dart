import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_realtime_service.dart';
import 'u_login.dart';
import 'a_users.dart';
import 'a_news.dart';
import 'package:stronghub/main.dart';

class DashboardPageAdmin extends StatefulWidget {
  const DashboardPageAdmin({super.key});

  @override
  State<DashboardPageAdmin> createState() => _DashboardPageAdminState();
}

class _DashboardPageAdminState extends State<DashboardPageAdmin> {
  String? userEmail = "";

  int totalUsers = 0;
  int activeMembers = 0;
  int inactiveMembers = 0;
  int totalNews = 0;

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadSummaryData();
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
    await prefs.remove('adminEmail');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPageUser()),
    );
  }

  Future<void> _loadSummaryData() async {
    final users = await FirebaseRealtimeService.fetchAllUsers();
    final membershipStats = await FirebaseRealtimeService.fetchMembershipStats(
      users,
    );
    final newsCount = await FirebaseRealtimeService.fetchNewsCount();

    setState(() {
      totalUsers = users.length;
      activeMembers = membershipStats['active'] ?? 0;
      inactiveMembers = membershipStats['inactive'] ?? 0;
      totalNews = newsCount;
    });
  }

  Widget _dashboardView() {
    final stats = [
      {
        "title": "Total Users",
        "count": totalUsers,
        "color": Colors.blue,
        "icon": Icons.people,
      },
      {
        "title": "Active Members",
        "count": activeMembers,
        "color": Colors.green,
        "icon": Icons.verified,
      },
      {
        "title": "Inactive Members",
        "count": inactiveMembers,
        "color": Colors.orange,
        "icon": Icons.cancel,
      },
      {
        "title": "Total News",
        "count": totalNews,
        "color": Colors.purple,
        "icon": Icons.article,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Selamat datang ${userEmail ?? 'Admin'}!",
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 20),
          const Text(
            "Ringkasan Data",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...stats.map(
            (stat) => Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: _summaryCard(
                stat['title'] as String,
                stat['count'] as int,
                stat['color'] as Color,
                stat['icon'] as IconData,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, int count, Color color, IconData icon) {
    // 🔹 Tentukan satuan
    String unit;
    if (title.contains("News")) {
      unit = "berita";
    } else {
      unit = "users";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
        border: Border(left: BorderSide(color: color, width: 6)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$count $unit', // <-- gunakan satuan di sini
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _dashboardView(),
      const UsersPageAdmin(),
      const NewsPageAdmin(),
    ];

    bool showAppBar = currentIndex == 0;

    return Scaffold(
      backgroundColor: background,

      appBar: showAppBar
          ? AppBar(
              backgroundColor: redDark,
              centerTitle: true,
              iconTheme: const IconThemeData(
                color: grayLight, // warna ikon menu
              ),
              title: Text(
                "Dashboard Admin StrongHub",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: whiteColor,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: "Logout",
                ),
              ],
            )
          : null,

      body: IndexedStack(index: currentIndex, children: pages),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) async {
          setState(() => currentIndex = i);

          // 🔹 Jika kembali ke Dashboard, refresh data
          if (i == 0) {
            await _loadSummaryData();
          }
        },
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'News'),
        ],
      ),
    );
  }
}
