import 'package:flutter/material.dart';
import '../services/firebase_realtime_service.dart';
import 'package:stronghub/main.dart';

class UsersPageAdmin extends StatefulWidget {
  const UsersPageAdmin({super.key});

  @override
  State<UsersPageAdmin> createState() => _UsersPageAdminState();
}

class _UsersPageAdminState extends State<UsersPageAdmin> {
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> memberships = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsersAndMemberships();
  }

  Future<void> _loadUsersAndMemberships() async {
    setState(() => isLoading = true);

    try {
      final u = await FirebaseRealtimeService.fetchAllUsers();
      final m = await FirebaseRealtimeService.fetchAllMemberships();

      setState(() {
        users = u;
        memberships = m;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("❌ Error loading users/memberships: $e");
    }
  }

  Map<String, dynamic>? _getMembership(String uid) {
    final mem = memberships.firstWhere(
      (m) => m['userId'] == uid,
      orElse: () => {},
    );
    return mem.isNotEmpty ? mem : null;
  }

  Future<void> _cancelMembership(String uid) async {
    final mem = memberships.firstWhere(
      (m) => m['userId'] == uid && m['status'] == 'active',
      orElse: () => {},
    );

    if (mem.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada membership aktif")),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Konfirmasi"),
        content: const Text(
          "Apakah Anda yakin ingin membatalkan membership ini?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Ya"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await FirebaseRealtimeService.cancelMembership(
      mem['orderId'],
    );
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Membership berhasil dibatalkan")),
      );
      _loadUsersAndMemberships();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal membatalkan membership")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: users.map((user) {
          final membership = _getMembership(user['uid']);
          final membershipType = membership != null
              ? membership['membershipType']
              : '-';
          final isActive =
              membership != null && membership['status'] == 'active';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isActive ? Icons.check_circle : Icons.cancel,
                        color: isActive ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        user['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Email: ${user['email']}"),
                  Text("Phone: ${user['phone']}"),
                  Text("Membership: $membershipType"),
                  if (isActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _cancelMembership(user['uid']),
                        child: const Text("Batalkan Membership"),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
