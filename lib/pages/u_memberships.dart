import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stronghub/main.dart';
import '../services/firebase_realtime_service.dart';
import 'u_payment.dart';

class MembershipsPageUser extends StatefulWidget {
  const MembershipsPageUser({super.key});

  @override
  State<MembershipsPageUser> createState() => _MembershipsPageUserState();
}

class _MembershipsPageUserState extends State<MembershipsPageUser> {
  bool isLoading = true;
  List<Map<String, dynamic>> membershipList = [];
  bool hasActiveMembership = false;

  @override
  void initState() {
    super.initState();
    _loadMembershipTypes();
    _checkActiveMembership();
  }

  /// 🔹 Ambil daftar membership dari Firebase
  Future<void> _loadMembershipTypes() async {
    try {
      final data = await FirebaseRealtimeService.fetchMembershipTypes();
      setState(() {
        membershipList = data;
        isLoading = false;
      });
      await _checkActiveMembership();
    } catch (e) {
      debugPrint("❌ Error fetch membership: $e");
      setState(() => isLoading = false);
    }
  }

  /// 🔹 Mapping image berdasarkan tipe membership
  String _membershipImage(String name) {
    switch (name.toLowerCase()) {
      case "gold":
        return "assets/images/Gold.png";
      case "platinum":
        return "assets/images/Platinum.png";
      case "silver":
        return "assets/images/Silver.png";
      default:
        return "assets/images/Silver.png";
    }
  }

  /// 🔹 Format harga ke Rupiah
  String _formatRupiah(num price) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(price);
  }

  Future<void> _checkActiveMembership() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('userEmail');
    if (email == null) return;

    final user = await FirebaseRealtimeService.getUserDataByEmail(email);
    if (user == null) return;

    final userId = user['uid'];

    // Ambil semua memberships
    final url = Uri.parse(
      "${FirebaseRealtimeService.baseUrl}/memberships.json",
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic>? data = json.decode(response.body);
      if (data == null) return;

      // Cek apakah ada membership active milik user
      bool foundActive = data.entries.any((e) {
        final m = e.value;
        return m['userId'] == userId && m['status'] == "active";
      });

      setState(() {
        hasActiveMembership = foundActive;
      });
    }
  }

  /// 🔹 UI CARD Membership
  Widget _buildMembershipCard(Map<String, dynamic> item) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 FOTO DI KIRI
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                _membershipImage(item['name']),
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 16),

            // 📌 TEKS DI KANAN
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ⭐ Nama Membership
                  Text(
                    item['name'],
                    style: const TextStyle(
                      color: blackPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 💬 Benefit
                  Text(
                    item['benefits'],
                    style: const TextStyle(
                      color: grayDark,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 💰 Harga & Durasi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatRupiah(item['price']),
                        style: const TextStyle(
                          color: redDark,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${item['durationDays']} hari",
                        style: const TextStyle(color: grayMedium, fontSize: 14),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 🔘 Tombol Pesan
                  // 🔘 Tombol Pesan
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasActiveMembership
                            ? blackPrimary
                            : redDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: hasActiveMembership
                          ? null
                          : () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final email = prefs.getString('userEmail');
                              if (email == null) return;

                              final user =
                                  await FirebaseRealtimeService.getUserDataByEmail(
                                    email,
                                  );
                              if (user == null) return;

                              final userId = user['uid'];

                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PaymentMemberships(
                                    membershipType: item['name'],
                                    price: item['price'],
                                    benefits: item['benefits'],
                                    userId: userId,
                                  ),
                                ),
                              );

                              // ⬅️ Setelah kembali dari pembayaran, refresh status membership
                              await _checkActiveMembership();
                              setState(() {});
                            },
                      child: Text(
                        hasActiveMembership
                            ? "Member Sudah Aktif"
                            : "Pesan Sekarang",
                        style: TextStyle(
                          color: hasActiveMembership
                              ? blackPrimary
                              : whiteColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: redDark));
    }

    return Container(
      color: background,
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: membershipList.length,
        itemBuilder: (context, index) {
          return _buildMembershipCard(membershipList[index]);
        },
      ),
    );
  }
}
