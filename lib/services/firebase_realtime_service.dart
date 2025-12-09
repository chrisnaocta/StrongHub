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

  /// /// 🔹 Menambah USER sebagai ADMIN
  static Future<bool> registerUserasAdmin({
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
              return false;
            }
          }
        }

        // Generate UID berdasarkan role 'user'
        int nextNumber = 101; // default jika belum ada user
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

        // Data user baru
        final newUser = {
          "name": name,
          "email": email,
          "password": hashedPassword,
          "phone": phone,
          "role": "user",
          "createdAt": DateTime.now().toString().split(' ')[0],
        };

        // Simpan ke Firebase
        final putResponse = await http.patch(
          Uri.parse('$baseUrl/users/$newUid.json'),
          body: json.encode(newUser),
        );

        if (putResponse.statusCode == 200) {
          print('✅ Register berhasil dengan UID $newUid');
          return true;
        } else {
          print('❌ Gagal simpan user: ${putResponse.body}');
          return false;
        }
      }

      return false;
    } catch (e) {
      print('❌ Error registerUser: $e');
      return false;
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

      // 3. Format expiredAt = +1 tahun
      final now = DateTime.now();
      final dateParsed = DateTime.parse(activatedAtCustom.replaceAll(" ", "T"));
      final expiredAt = DateTime(
        dateParsed.year + 1,
        dateParsed.month,
        dateParsed.day,
      );

      final data = {
        "userId": userId,
        "membershipType": membershipType,
        "price": price,
        "orderDate": now.toIso8601String().substring(0, 10),
        "activatedAt": activatedAtCustom,
        "expiredAt":
            "${expiredAt.year}-${expiredAt.month.toString().padLeft(2, '0')}-${expiredAt.day.toString().padLeft(2, '0')}",
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
}
