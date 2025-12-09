import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/firebase_realtime_service.dart';

// Pages
import 'pages/u_login.dart';
import 'pages/a_dashboard.dart';
import 'pages/u_home.dart';

// 🎨 Warna Tema StrongHub
const Color background = Color(0xFFF2F2F2); // background halus
const Color redPrimary = Color(0xFFE50914); // merah utama (premium)
const Color redSoft = Color(0xFFFF6B6B); // merah lebih lembut, friendly
const Color redDark = Color(0xFFB0060E); // merah gelap untuk aksen kuat

const Color grayLight = Color(0xFFF2F2F2); // background halus
const Color grayMedium = Color(0xFFBDBDBD); // border / text secondary
const Color grayDark = Color(0xFF4F4F4F); // teks judul

const Color blackPrimary = Color(0xFF1A1A1A); // teks utama / heading
const Color whiteColor = Color(0xFFFFFFFF); // elemen cerah / kontras tinggi

const Color orange = Color(0xFFFFA500);
const Color yellow = Color.fromARGB(255, 245, 127, 23);

const Color silverColor = Color(0xFFC0C0C0); // silver metalic
const Color goldAccent = Color(0xFFFFD54F); // gold premium
const Color platinumColor = Color(0xFF8FD1C5); // platinum metalic

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  bool isLoginUser = prefs.getBool('isLoginUser') ?? false;
  bool isLoginAdmin = prefs.getBool('isLoginAdmin') ?? false;

  // Cek koneksi ke Firebase Realtime Database (opsional)
  final connected = await FirebaseRealtimeService.testConnection();
  print(
    connected ? "🔥 Koneksi Firebase berhasil!" : "⚠️ Gagal koneksi Firebase!",
  );

  // Tentukan halaman awal (tetapi LoginPageUser tetap default)
  Widget startPage;
  if (isLoginAdmin) {
    startPage = DashboardPageAdmin();
  } else if (isLoginUser) {
    startPage = DashboardPageUser();
  } else {
    startPage = const LoginPageUser(); // SELALU default
  }

  runApp(MyApp(startPage: startPage));
}

class MyApp extends StatelessWidget {
  final Widget startPage;
  const MyApp({super.key, required this.startPage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: startPage);
  }
}
