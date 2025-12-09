import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stronghub/main.dart';
import '../services/firebase_realtime_service.dart';

class StatusPageUser extends StatefulWidget {
  const StatusPageUser({super.key});

  @override
  State<StatusPageUser> createState() => _StatusPageUserState();
}

class _StatusPageUserState extends State<StatusPageUser> {
  bool isLoading = true;
  Map<String, dynamic>? activeMembership;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("userEmail");

      if (email == null) return;

      final user = await FirebaseRealtimeService.getUserDataByEmail(email);
      if (user == null) return;

      final userId = user['uid'];

      final membership =
          await FirebaseRealtimeService.getActiveMembershipByUser(userId);

      setState(() {
        activeMembership = membership;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ ERROR load status: $e");
      setState(() => isLoading = false);
    }
  }

  String _formatRupiah(num price) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(price);
  }

  Widget _statusCard(Map<String, dynamic> m) {
    // Tentukan warna sesuai membership type
    final type = m["membershipType"].toString().toLowerCase();

    Color badgeBg = blackPrimary;
    Color badgeBorder = blackPrimary;
    Color badgeText = blackPrimary;

    if (type == "silver") {
      badgeBg = silverColor;
      badgeBorder = silverColor;
      badgeText = blackPrimary;
    } else if (type == "gold") {
      badgeBg = goldAccent;
      badgeBorder = goldAccent;
      badgeText = blackPrimary;
    } else if (type == "platinum") {
      badgeBg = platinumColor;
      badgeBorder = platinumColor;
      badgeText = blackPrimary;
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: redDark, width: 2), // 🔥 border merah
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🔥 Badge membership
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: badgeBorder, width: 1.4),
            ),
            child: Text(
              "${m['membershipType'].toString().toUpperCase()} MEMBER",
              style: TextStyle(
                color: badgeText,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            "Status Keanggotaan",
            style: TextStyle(
              color: blackPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          _rowInfo("Membership", m["membershipType"]),
          _rowInfo("Order ID", m["orderId"]),
          _rowInfo("Mulai Aktif", m["activatedAt"]),
          _rowInfo("Berakhir Pada", m["expiredAt"]),
          _rowInfo("Harga", "Rp ${_formatRupiah(m["price"])}"),
          _rowInfo("Tanggal Order", m["orderDate"]),

          const SizedBox(height: 20),

          // 🔥 Status Active Box
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            width: double.infinity,
            decoration: BoxDecoration(
              color:
                  badgeBorder, // warna mengikuti membership (silver/gold/platinum)
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                "ACTIVE",
                style: TextStyle(
                  color: (type == "gold" || type == "platinum")
                      ? blackPrimary
                      : whiteColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: grayDark, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              color: blackPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: redDark));
    }

    if (activeMembership == null) {
      return Center(
        child: Text(
          "Anda belum memiliki membership aktif",
          style: TextStyle(
            color: grayDark,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: FractionallySizedBox(
          widthFactor: 0.90, // biar tampil elegan di tengah
          child: _statusCard(activeMembership!),
        ),
      ),
    );
  }
}
