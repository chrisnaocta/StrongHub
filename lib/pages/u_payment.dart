import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_realtime_service.dart';
import 'package:stronghub/main.dart';

class PaymentMemberships extends StatefulWidget {
  final String membershipType;
  final int price;
  final String userId;
  final String benefits;

  const PaymentMemberships({
    super.key,
    required this.membershipType,
    required this.price,
    required this.userId,
    required this.benefits,
  });

  @override
  State<PaymentMemberships> createState() => _PaymentMembershipsState();
}

class _PaymentMembershipsState extends State<PaymentMemberships> {
  bool isLoading = false;
  DateTime? selectedDate;

  /// 1 = user pilih tanggal, 2 = aktivasi setelah bayar
  int activationMode = 1;

  String _formatRupiah(num price) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(price);
  }

  String formatDateTime(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
  }

  /// ===========================
  /// PICK DATE + TIME
  /// ===========================
  Future<void> pickActivationDate() async {
    final now = DateTime.now();

    // === PICK DATE ===
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (pickedDate == null) return;

    // === PICK TIME ===
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
      0, // second = 0 supaya rapi
    );

    setState(() {
      selectedDate = combined;
    });
  }

  /// ===========================
  /// PROCESS PEMBAYARAN
  /// ===========================
  Future<void> processPayment() async {
    DateTime finalActivation;

    if (activationMode == 1) {
      if (selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pilih tanggal aktivasi terlebih dahulu!"),
            backgroundColor: Colors.red,
          ),
        );
        pickActivationDate();
        return;
      }
      finalActivation = selectedDate!;
    } else {
      finalActivation = DateTime.now();
    }

    setState(() => isLoading = true);

    final success = await FirebaseRealtimeService.orderMembership(
      userId: widget.userId,
      membershipType: widget.membershipType,
      price: widget.price,
      activatedAtCustom: formatDateTime(finalActivation),
    );

    setState(() => isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Pembayaran berhasil! Membership '${widget.membershipType}' aktif.",
          ),
          backgroundColor: redPrimary,
        ),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal memproses pembayaran."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// ===========================
  /// DIALOG PEMBAYARAN
  /// ===========================
  void showPaymentDialog(String method) {
    Widget content;

    if (method == "QRIS") {
      content = Image.asset('assets/images/qris.png', width: 200, height: 200);
    } else {
      final randomVA = Random().nextInt(90000000) + 10000000;
      content = Text(
        "Nomor Virtual Account:\nVA$randomVA",
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: blackPrimary,
        ),
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text(
          "Pembayaran Berhasil ✅",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: content,
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await processPayment();
            },
            child: const Text(
              "Selesai",
              style: TextStyle(color: redPrimary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final membershipImage = "assets/images/${widget.membershipType}.png";

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: redDark,
        title: const Text(
          "Pembayaran Membership",
          style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: whiteColor),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                membershipImage,
                width: 180,
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.image_not_supported,
                  size: 80,
                  color: grayMedium,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              "${widget.membershipType} Membership",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: blackPrimary,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              "Harga",
              style: TextStyle(fontSize: 16, color: grayDark),
            ),
            Text(
              _formatRupiah(widget.price),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: redPrimary,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              "Benefits:",
              style: TextStyle(
                fontSize: 18,
                color: blackPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.benefits,
              style: const TextStyle(fontSize: 15, color: grayDark),
            ),

            const SizedBox(height: 25),

            // ===============================
            // MODE AKTIVASI
            // ===============================
            const Text(
              "Mode Aktivasi",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: blackPrimary,
              ),
            ),

            RadioListTile(
              value: 1,
              groupValue: activationMode,
              title: const Text("Saya pilih tanggal aktivasi"),
              onChanged: (v) => setState(() => activationMode = v!),
            ),

            RadioListTile(
              value: 2,
              groupValue: activationMode,
              title: const Text("Aktivasi otomatis setelah pembayaran"),
              onChanged: (v) => setState(() => activationMode = v!),
            ),

            const SizedBox(height: 10),

            if (activationMode == 1) ...[
              const Text(
                "Tanggal & Waktu Aktivasi",
                style: TextStyle(
                  fontSize: 18,
                  color: blackPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: pickActivationDate,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: whiteColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: grayMedium),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedDate == null
                            ? "Pilih tanggal & waktu"
                            : formatDateTime(selectedDate!),
                        style: TextStyle(
                          color: selectedDate == null ? grayDark : blackPrimary,
                          fontSize: 16,
                        ),
                      ),
                      const Icon(Icons.access_time, color: redDark),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
            ],

            const Text(
              "Metode Pembayaran",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: blackPrimary,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: const Icon(Icons.qr_code_2, color: redDark),
                title: const Text("QRIS"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  if (activationMode == 1 && selectedDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Pilih tanggal terlebih dahulu!"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    pickActivationDate();
                    return;
                  }
                  showPaymentDialog("QRIS");
                },
              ),
            ),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: const Icon(Icons.account_balance, color: redDark),
                title: const Text("Virtual Account"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  if (activationMode == 1 && selectedDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Pilih tanggal terlebih dahulu!"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    pickActivationDate();
                    return;
                  }
                  showPaymentDialog("VA");
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
