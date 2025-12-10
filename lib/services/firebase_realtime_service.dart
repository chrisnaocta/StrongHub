import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class FirebaseRealtimeService {
  static const String baseUrl =
      'https://stronghub-64d76-default-rtdb.asia-southeast1.firebasedatabase.app/';

  /// 🔹 Tes koneksi Firebase
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users.json'));
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Gagal konek Firebase: $e');
      return false;
    }
  }

  /// 🔹 Hash password
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 🔹 Login USER (email & password)
  static Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users.json'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>?;

        if (data != null) {
          final hashedInput = hashPassword(password);

          for (var entry in data.entries) {
            final user = entry.value as Map<String, dynamic>;

            // Cocokkan email & hashed password
            if (user['email'] == email && user['password'] == hashedInput) {
              // Cegah login jika role == admin
              if (user['role'] == 'admin') {
                throw Exception("Tidak bisa login sebagai admin");
              }

              print('✅ Login berhasil sebagai ${user['role']}');
              // ➜ return user + id (key)
              return {'id': entry.key, ...user};
            }
          }
        }
      }
      return null;
    } catch (e) {
      print('❌ Error login: $e');
      return null;
    }
  }

  /// 🔹 Login ADMIN (email & password)
  static Future<Map<String, dynamic>?> loginAdmin({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users.json'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>?;

        if (data != null) {
          final hashedInput = hashPassword(password);

          for (var entry in data.entries) {
            final user = entry.value as Map<String, dynamic>;

            // ✅ Cocokkan email dan password
            if (user['email'] == email && user['password'] == hashedInput) {
              // 🚫 Cegah login jika role == user
              if (user['role'] == 'customer') {
                throw Exception("Tidak bisa login sebagai user");
              }

              print('✅ Login berhasil sebagai ${user['role']}');
              // ➜ return user + id (key)
              return {'id': entry.key, ...user};
            }
          }
        }
      }

      return null;
    } catch (e) {
      print('❌ Error login: $e');
      return null;
    }
  }

  /// 🔹 Ambil semua berita dari Firebase Realtime Database
  static Future<List<Map<String, dynamic>>> fetchNews() async {
    final url = Uri.parse('$baseUrl/news.json');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic>? data = json.decode(response.body);
      if (data == null) return [];

      return data.entries.map((e) {
        final value = e.value as Map<String, dynamic>;
        return {
          'id': e.key,
          'title': value['title'] ?? 'Tanpa Judul',
          'description': value['description'] ?? '',
          'content': value['content'] ?? '',
          'createdAt': value['createdAt'] ?? '',
        };
      }).toList();
    } else {
      throw Exception('Gagal memuat berita');
    }
  }

  /// 🔹 Ambil data lengkap user (uid, email, name, phone) berdasarkan email login
  static Future<Map<String, dynamic>?> getUserDataByEmail(String email) async {
    final url = Uri.parse('$baseUrl/users.json');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic>? data = json.decode(response.body);
      if (data == null) return null;

      for (final entry in data.entries) {
        final user = entry.value as Map<String, dynamic>;
        if (user['email'] == email) {
          return {
            'uid': entry.key,
            'email': user['email'],
            'name': user['name'],
            'phone': user['phone'],
          };
        }
      }
    }
    return null;
  }

  /// 🔹 Register USER (Sisi Customer)
  static Future<String?> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String gender,
  }) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users.json'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>?;

        // Cek email sudah ada
        if (data != null) {
          for (var user in data.values) {
            final u = user as Map<String, dynamic>;
            if (u['email'] == email) {
              print('❌ Email sudah digunakan');
              return null;
            }
          }
        }

        // Generate UID
        int nextNumber = 101;
        if (data != null) {
          final userIds = data.keys
              .where((k) => k.startsWith('uid_C_'))
              .map((k) => int.tryParse(k.split('_').last) ?? 0)
              .toList();
          if (userIds.isNotEmpty) {
            nextNumber = userIds.reduce((a, b) => a > b ? a : b) + 1;
          }
        }

        final newUid = 'uid_C_$nextNumber';

        // Hash password
        final hashedPassword = hashPassword(password);

        // Data baru
        final newUser = {
          "name": name,
          "email": email,
          "gender": gender,
          "password": hashedPassword,
          "phone": phone,
          "role": "customer",
          "createdAt": DateTime.now().toString().split(' ')[0],
        };

        // Simpan ke Firebase
        final putResponse = await http.patch(
          Uri.parse('$baseUrl/users/$newUid.json'),
          body: json.encode(newUser),
        );

        if (putResponse.statusCode == 200) {
          print('✅ Register berhasil dengan UID $newUid');
          return newUid; // 🔥 kembalikan UID
        } else {
          print('❌ Gagal simpan user: ${putResponse.body}');
          return null;
        }
      }

      return null;
    } catch (e) {
      print('❌ Error registerUser: $e');
      return null;
    }
  }

  /// 🔹 Register ADMIN
  static Future<String?> registerAdmin({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      // Ambil semua user
      final response = await http.get(Uri.parse('$baseUrl/users.json'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>?;

        // Cek email sudah ada
        if (data != null) {
          for (var user in data.values) {
            final u = user as Map<String, dynamic>;
            if (u['email'] == email) {
              print('❌ Email sudah digunakan');
              return null;
            }
          }
        }

        // Generate UID berdasarkan role 'user'
        int nextNumber = 501; // default jika belum ada user
        if (data != null) {
          final userIds = data.keys
              .where((k) => k.startsWith('uid_A_'))
              .map((k) => int.tryParse(k.split('_').last) ?? 0)
              .toList();
          if (userIds.isNotEmpty) {
            nextNumber = userIds.reduce((a, b) => a > b ? a : b) + 1;
          }
        }
        final newUid = 'uid_A_$nextNumber';

        // Hash password
        final hashedPassword = hashPassword(password);

        // Data user baru
        final newUser = {
          "name": name,
          "email": email,
          "password": hashedPassword,
          "phone": phone,
          "role": "admin",
          "createdAt": DateTime.now().toString().split(' ')[0],
        };

        // Simpan ke Firebase
        final putResponse = await http.patch(
          Uri.parse('$baseUrl/users/$newUid.json'),
          body: json.encode(newUser),
        );

        if (putResponse.statusCode == 200) {
          print('✅ Register berhasil dengan UID $newUid');
          return newUid;
        } else {
          print('❌ Gagal simpan user: ${putResponse.body}');
          return null;
        }
      }

      return null;
    } catch (e) {
      print('❌ Error registerUser: $e');
      return null;
    }
  }

  /// 🔹 Ambil semua membership types
  static Future<List<Map<String, dynamic>>> fetchMembershipTypes() async {
    final url = Uri.parse('$baseUrl/membership_types.json');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic>? data = json.decode(response.body);
      if (data == null) return [];

      return data.entries.map((e) {
        final value = e.value as Map<String, dynamic>;
        return {
          'id': e.key,
          'name': value['name'],
          'benefits': value['benefits'],
          'durationDays': value['durationDays'],
          'price': value['price'],
        };
      }).toList();
    } else {
      throw Exception("Gagal memuat membership types");
    }
  }

  /// 🔹 Order membership baru dengan orderId otomatis
  static Future<bool> orderMembership({
    required String userId,
    required String membershipType,
    required int price,
    required String activatedAtCustom,
  }) async {
    try {
      final getUrl = Uri.parse("$baseUrl/memberships.json");

      // 1. Ambil semua membership
      final getResponse = await http.get(getUrl);
      Map<String, dynamic> existing = {};

      if (getResponse.statusCode == 200 && getResponse.body != "null") {
        existing = json.decode(getResponse.body);
      }

      // 2. Generate order ID
      int count = existing.length + 1;
      String newOrderId = "order${count.toString().padLeft(3, '0')}";

      // 3. Parse activatedAtCustom menjadi DateTime
      final dateParsed = DateTime.parse(activatedAtCustom.replaceAll(" ", "T"));

      // 4. expiredAt = +1 tahun (sama jam/menit/detik)
      final expiredDate = DateTime(
        dateParsed.year + 1,
        dateParsed.month,
        dateParsed.day,
        dateParsed.hour,
        dateParsed.minute,
        dateParsed.second,
      );

      // Format expired date (YYYY-MM-DD HH:mm:ss)
      final expiredFormatted =
          "${expiredDate.year}-${expiredDate.month.toString().padLeft(2, '0')}-${expiredDate.day.toString().padLeft(2, '0')} "
          "${expiredDate.hour.toString().padLeft(2, '0')}:${expiredDate.minute.toString().padLeft(2, '0')}:${expiredDate.second.toString().padLeft(2, '0')}";

      final now = DateTime.now();

      final data = {
        "userId": userId,
        "membershipType": membershipType,
        "price": price,
        "orderDate": now.toIso8601String().substring(0, 10),
        "activatedAt": activatedAtCustom,
        "expiredAt": expiredFormatted,
        "status": "active",
      };

      final putUrl = Uri.parse("$baseUrl/memberships/$newOrderId.json");
      final putResponse = await http.put(putUrl, body: json.encode(data));

      return putResponse.statusCode == 200;
    } catch (e) {
      print("ERROR orderMembership: $e");
      return false;
    }
  }

  /// 🔹 Ambil membership aktif milik user
  static Future<Map<String, dynamic>?> getActiveMembershipByUser(
    String userId,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/memberships.json");
      final res = await http.get(url);

      if (res.statusCode != 200) return null;

      final Map<String, dynamic>? data = json.decode(res.body);
      if (data == null) return null;

      for (var entry in data.entries) {
        final m = entry.value;
        if (m['userId'] == userId && m['status'] == "active") {
          return {
            "orderId": entry.key,
            "membershipType": m["membershipType"],
            "activatedAt": m["activatedAt"],
            "expiredAt": m["expiredAt"],
            "price": m["price"],
            "orderDate": m["orderDate"],
          };
        }
      }
      return null;
    } catch (e) {
      print("❌ ERROR getActiveMembershipByUser: $e");
      return null;
    }
  }

  /// 🔹 Ambil semua users
  static Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    final url = Uri.parse('$baseUrl/users.json');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic>? data = json.decode(response.body);
      if (data == null) return [];

      return data.entries
          .where((e) => e.key.startsWith('uid_C_')) // hanya customer
          .map((e) {
            final value = e.value as Map<String, dynamic>;
            return {
              'uid': e.key,
              'name': value['name'],
              'email': value['email'],
              'phone': value['phone'],
              'role': value['role'],
            };
          })
          .toList();
    } else {
      throw Exception("Gagal memuat users");
    }
  }

  /// 🔹 Ambil jumlah membership customer berdasarkan status
  /// users: daftar semua users dari tabel 'users'
  static Future<Map<String, int>> fetchMembershipStats(
    List<Map<String, dynamic>> users,
  ) async {
    final url = Uri.parse('$baseUrl/memberships.json');
    final response = await http.get(url);

    if (response.statusCode != 200) throw Exception("Gagal memuat memberships");

    final Map<String, dynamic>? data = json.decode(response.body);
    if (data == null) {
      // Semua users belum aktif
      return {
        'active': 0,
        'inactive': users.where((u) => u['role'] == 'customer').length,
      };
    }

    int active = 0;
    final activeUserIds = <String>{};

    data.forEach((key, value) {
      final Map<String, dynamic> m = value as Map<String, dynamic>;
      if (m['status'] == 'active') {
        active++;
        activeUserIds.add(m['userId']);
      }
    });

    // Hitung inactive sebagai customer yang tidak punya membership aktif
    final inactive = users
        .where(
          (u) => u['role'] == 'customer' && !activeUserIds.contains(u['uid']),
        )
        .length;

    return {'active': active, 'inactive': inactive};
  }

  /// 🔹 Ambil jumlah berita
  static Future<int> fetchNewsCount() async {
    final url = Uri.parse('$baseUrl/news.json');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic>? data = json.decode(response.body);
      return data?.length ?? 0;
    } else {
      throw Exception("Gagal memuat news");
    }
  }

  /// 🔹 Ambil semua memberships customer
  static Future<List<Map<String, dynamic>>> fetchAllMemberships() async {
    final url = Uri.parse('$baseUrl/memberships.json');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic>? data = json.decode(response.body);
      if (data == null) return [];

      return data.entries.map((e) {
        final value = e.value as Map<String, dynamic>;
        return {
          'orderId': e.key,
          'userId': value['userId'],
          'membershipType': value['membershipType'],
          'status': value['status'],
          'activatedAt': value['activatedAt'] ?? '',
          'expiredAt': value['expiredAt'] ?? '',
          'cancelledAt': value['cancelledAt'] ?? '',
        };
      }).toList();
    } else {
      throw Exception("Gagal memuat memberships");
    }
  }

  /// 🔹 Batalkan membership berdasarkan orderId
  static Future<bool> cancelMembership(String orderId) async {
    final now = DateTime.now();
    final cancelledAt =
        "${now.year.toString().padLeft(4, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')} "
        "${now.hour.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')}:"
        "${now.second.toString().padLeft(2, '0')}";

    final url = Uri.parse('$baseUrl/memberships/$orderId.json');

    // Ambil data membership dulu
    final getResponse = await http.get(url);
    if (getResponse.statusCode != 200) return false;

    final Map<String, dynamic> membershipData = json.decode(getResponse.body);
    membershipData['status'] = 'cancelled';
    membershipData['cancelledAt'] = cancelledAt;
    membershipData['membershipType'] = '-';

    // Update seluruh data membership
    final putResponse = await http.put(url, body: json.encode(membershipData));

    return putResponse.statusCode == 200;
  }

  /// 🔹 Ambil semua berita
  static Future<List<Map<String, dynamic>>> fetchAllNews() async {
    final url = Uri.parse('$baseUrl/news.json');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic>? data = json.decode(response.body);
      if (data == null) return [];

      return data.entries.map((e) {
        final value = e.value as Map<String, dynamic>;
        return {
          'id': e.key,
          'title': value['title'],
          'content': value['content'],
          'createdAt': value['createdAt'],
          'createdBy': value['createdBy'],
        };
      }).toList()..sort(
        (a, b) => b['createdAt'].compareTo(a['createdAt']),
      ); // terbaru di atas
    } else {
      throw Exception("Gagal memuat news");
    }
  }

  /// 🔹 Tambah berita baru dengan uid format news001, news002, dst.
  static Future<bool> addNewsWithId({
    required String title,
    required String content,
    required String createdBy,
  }) async {
    // Ambil semua news untuk menghitung ID berikutnya
    final allNews = await fetchAllNews();
    int nextIndex = allNews.length + 1;
    final newsId = 'news${nextIndex.toString().padLeft(3, '0')}';

    final now = DateTime.now();
    final createdAt =
        "${now.toIso8601String().split('T')[0]} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    final newsData = {
      'title': title,
      'content': content,
      'createdAt': createdAt,
      'createdBy': createdBy,
    };

    final url = Uri.parse('$baseUrl/news/$newsId.json');
    final response = await http.put(url, body: json.encode(newsData));

    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// 🔹 Ambil UID admin berdasarkan email
  static Future<String?> fetchAdminUidByEmail(String email) async {
    final url = Uri.parse('$baseUrl/users.json');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic>? data = json.decode(response.body);
      if (data == null) return null;

      final admin = data.entries.firstWhere(
        (e) => e.value['email'] == email && e.value['role'] == 'admin',
        orElse: () => MapEntry('', {}),
      );
      if (admin.key.isEmpty) return null;
      return admin.key;
    } else {
      throw Exception("Gagal memuat users");
    }
  }
}
