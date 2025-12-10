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

  String searchQuery = "";
  bool sortAsc = true;

  @override
  void initState() {
    super.initState();
    _loadUsersAndMemberships();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUsersAndMemberships(); // refresh otomatis ketika halaman muncul
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
        SnackBar(content: Text("Membership $uid berhasil dibatalkan")),
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

    // Search + Sorting
    List<Map<String, dynamic>> filteredUsers = users.where((u) {
      final name = u['name'].toString().toLowerCase();
      final email = u['email'].toString().toLowerCase();
      return name.contains(searchQuery) || email.contains(searchQuery);
    }).toList();

    filteredUsers.sort(
      (a, b) => sortAsc
          ? a['name'].compareTo(b['name'])
          : b['name'].compareTo(a['name']),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          /// 🔍 Search Bar + Sorting
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Cari berdasarkan nama/email",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() => searchQuery = value.toLowerCase());
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(sortAsc ? Icons.sort_by_alpha : Icons.sort),
                  onPressed: () {
                    setState(() => sortAsc = !sortAsc);
                  },
                ),
              ],
            ),
          ),

          /// List User
          ...filteredUsers.map((user) {
            final membership = _getMembership(user['uid']);

            String membershipText;
            bool isActive = false;

            if (membership == null) {
              membershipText = "Belum aktivasi";
            } else {
              if (membership['status'] == 'active') {
                membershipText = membership['membershipType'];
                isActive = true;
              } else {
                membershipText = membership['status']; // cancelled
              }
            }

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
                        Text(
                          " <${user['uid']}>",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: grayDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("Email: ${user['email']}"),
                    Text("Phone: ${user['phone']}"),
                    Text("Membership: $membershipText"),

                    /// Detail tanggal membership
                    if (membership != null) ...[
                      const SizedBox(height: 6),

                      if (membership['status'] == 'active') ...[
                        Text(
                          "Aktif sejak: ${membership['activatedAt']}",
                          style: const TextStyle(color: Colors.green),
                        ),
                        Text(
                          "Berlaku sampai: ${membership['expiredAt']}",
                          style: const TextStyle(color: Colors.green),
                        ),
                      ],

                      if (membership['status'] == 'cancelled') ...[
                        Text(
                          "Dibatalkan pada: ${membership['cancelledAt'] ?? '-'}",
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ],

                    if (isActive)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: redPrimary,
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
        ],
      ),
    );
  }
}
