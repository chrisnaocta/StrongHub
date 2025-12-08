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
            'uid': entry.key, // contoh: uid_U_101
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

        final newUid = 'uid_U_$nextNumber';

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
              .where((k) => k.startsWith('uid_U_'))
              .map((k) => int.tryParse(k.split('_').last) ?? 0)
              .toList();
          if (userIds.isNotEmpty) {
            nextNumber = userIds.reduce((a, b) => a > b ? a : b) + 1;
          }
        }
        final newUid = 'uid_U_$nextNumber';

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

  // /// 🔹 Ambil semua data destinasi dari Firebase Realtime Database
  // static Future<List<Map<String, dynamic>>> fetchDestinations() async {
  //   final url = Uri.parse('$baseUrl/destinations.json');
  //   final response = await http.get(url);

  //   if (response.statusCode == 200) {
  //     final Map<String, dynamic>? data = json.decode(response.body);
  //     if (data == null) return [];
  //     return data.entries.map((e) {
  //       final value = e.value as Map<String, dynamic>;
  //       return {
  //         'id': e.key,
  //         'name': value['name'] ?? 'Tanpa Nama',
  //         'location': value['location'] ?? 'Tidak diketahui',
  //         'description': value['description'] ?? '',
  //         'price': value['price'] ?? 0,
  //         'imageUrl': value['imageUrl'] ?? '',
  //       };
  //     }).toList();
  //   } else {
  //     throw Exception('Gagal memuat data destinasi');
  //   }
  // }

  // /// 🔹 Ambil semua review dari Firebase
  // static Future<List<Map<String, dynamic>>> fetchReviews(
  //   String destinationId,
  // ) async {
  //   final url = Uri.parse('$baseUrl/reviews.json');
  //   final response = await http.get(url);

  //   if (response.statusCode == 200) {
  //     final Map<String, dynamic>? data = json.decode(response.body);
  //     if (data == null) return [];
  //     final filtered = data.entries
  //         .map((e) {
  //           final value = e.value as Map<String, dynamic>;
  //           return {
  //             'id': e.key,
  //             'comment': value['comment'] ?? '',
  //             'createdAt': value['createdAt'] ?? '',
  //             'destinationId': value['destinationId'] ?? '',
  //             'rating': value['rating'] ?? 0,
  //             'userId': value['userId'] ?? '',
  //           };
  //         })
  //         .where((r) => r['destinationId'] == destinationId)
  //         .toList();
  //     return filtered;
  //   } else {
  //     throw Exception('Gagal memuat ulasan');
  //   }
  // }

  // /// 🔹 Simpan destinasi ke tabel "saved_destinations"
  // static Future<void> saveDestination(String userId, String destId) async {
  //   final url = Uri.parse('$baseUrl/saved_destinations/$userId/$destId.json');
  //   final response = await http.put(url, body: json.encode(true));

  //   if (response.statusCode != 200) {
  //     throw Exception('Gagal menyimpan destinasi');
  //   }
  // }

  // /// 🔹 Hapus destinasi dari tabel "saved_destinations"
  // static Future<void> removeSavedDestination(
  //   String userId,
  //   String destId,
  // ) async {
  //   final url = Uri.parse('$baseUrl/saved_destinations/$userId/$destId.json');
  //   final response = await http.delete(url);

  //   if (response.statusCode != 200) {
  //     throw Exception('Gagal menghapus destinasi dari favorit');
  //   }
  // }

  // /// 🔹 Cek apakah destinasi disimpan oleh user tertentu
  // static Future<bool> isDestinationSaved(String userId, String destId) async {
  //   final url = Uri.parse('$baseUrl/saved_destinations/$userId/$destId.json');
  //   final response = await http.get(url);
  //   if (response.statusCode == 200) {
  //     final data = json.decode(response.body);
  //     return data == true;
  //   }
  //   return false;
  // }

  // /// 🔹 Ambil daftar ID destinasi yang disimpan user
  // static Future<List<String>> fetchSavedDestinations(String userId) async {
  //   final url = Uri.parse('$baseUrl/saved_destinations/$userId.json');
  //   final response = await http.get(url);

  //   if (response.statusCode == 200) {
  //     final Map<String, dynamic>? data = json.decode(response.body);
  //     if (data == null) return [];
  //     return data.keys.toList();
  //   }
  //   return [];
  // }

  // /// 🔹 Ambil review berdasarkan destinationId
  // static Future<List<Map<String, dynamic>>> fetchReviewsByDestination(
  //   String destId,
  // ) async {
  //   final url = Uri.parse('$baseUrl/reviews.json');
  //   final response = await http.get(url);

  //   if (response.statusCode == 200) {
  //     final Map<String, dynamic>? data = json.decode(response.body);
  //     if (data == null) return [];

  //     return data.entries
  //         .where((e) => e.value['destinationId'] == destId)
  //         .map(
  //           (e) => {
  //             'id': e.key,
  //             'rating': e.value['rating'] ?? 0,
  //             'comment': e.value['comment'] ?? '',
  //             'userId': e.value['userId'] ?? '',
  //             'createdAt': e.value['createdAt'] ?? '',
  //             'destinationId': e.value['destinationId'] ?? destId,
  //           },
  //         )
  //         .toList();
  //   }
  //   return [];
  // }

  // /// 🔹 Ambil rating milik user tertentu pada destinasi tertentu
  // static Future<double?> fetchUserRating(
  //   String userId,
  //   String destinationId,
  // ) async {
  //   final url = Uri.parse('$baseUrl/reviews.json');
  //   final response = await http.get(url);

  //   if (response.statusCode == 200) {
  //     final Map<String, dynamic>? data = json.decode(response.body);
  //     if (data == null) return null;

  //     for (var entry in data.entries) {
  //       final review = entry.value as Map<String, dynamic>;
  //       if (review['userId'] == userId &&
  //           review['destinationId'] == destinationId) {
  //         final rating = (review['rating'] ?? 0).toDouble();
  //         return rating;
  //       }
  //     }
  //   }
  //   return null; // belum pernah review
  // }

  // /// 🔹 Ambil review user berdasarkan bookingId
  // static Future<Map<String, dynamic>?> fetchUserReviewByBookingId(
  //   String userId,
  //   String bookingId,
  // ) async {
  //   final url = Uri.parse('$baseUrl/reviews.json');
  //   final response = await http.get(url);

  //   if (response.statusCode == 200) {
  //     final Map<String, dynamic>? data = json.decode(response.body);
  //     if (data == null) return null;

  //     for (var entry in data.entries) {
  //       final review = entry.value as Map<String, dynamic>;
  //       if (review['userId'] == userId && review['bookingId'] == bookingId) {
  //         return {
  //           'id': entry.key,
  //           'destinationId': review['destinationId'],
  //           'rating': (review['rating'] ?? 0).toDouble(),
  //           'comment': review['comment'] ?? '',
  //           'createdAt': review['createdAt'] ?? '',
  //           'bookingId': review['bookingId'] ?? '',
  //         };
  //       }
  //     }
  //   }
  //   return null; // belum pernah review booking ini
  // }

  // /// 🔹 Tambah booking baru
  // static Future<bool> addBooking(Map<String, dynamic> bookingData) async {
  //   try {
  //     final response = await http.get(Uri.parse('$baseUrl/bookings.json'));
  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic>? data = json.decode(response.body);

  //       // Generate ID booking unik: book001, book002, ...
  //       int nextNumber = 1;
  //       if (data != null && data.isNotEmpty) {
  //         final ids = data.keys
  //             .where((k) => k.startsWith('book'))
  //             .map((k) => int.tryParse(k.replaceAll('book', '')) ?? 0)
  //             .toList();
  //         if (ids.isNotEmpty)
  //           nextNumber = ids.reduce((a, b) => a > b ? a : b) + 1;
  //       }
  //       final newId = 'book${nextNumber.toString().padLeft(3, '0')}';

  //       final putResponse = await http.put(
  //         Uri.parse('$baseUrl/bookings/$newId.json'),
  //         body: json.encode(bookingData),
  //       );

  //       return putResponse.statusCode == 200;
  //     }
  //     return false;
  //   } catch (e) {
  //     print('❌ Error addBooking: $e');
  //     return false;
  //   }
  // }

  // /// 🔹 Hapus destinasi tersimpan user setelah dibayar
  // static Future<bool> removeSavedDestinationAfterPayment({
  //   required String userId,
  //   required String destinationId,
  // }) async {
  //   try {
  //     final url = Uri.parse(
  //       '$baseUrl/saved_destinations/$userId/$destinationId.json',
  //     );
  //     final response = await http.delete(url);

  //     if (response.statusCode == 200) {
  //       print('✅ Destinasi $destinationId dihapus dari saved $userId');
  //       return true;
  //     } else {
  //       print('❌ Gagal hapus destinasi: ${response.body}');
  //       return false;
  //     }
  //   } catch (e) {
  //     print('❌ Error removeSavedDestination: $e');
  //     return false;
  //   }
  // }

  // /// 🔹 Ambil booking berdasarkan userId lengkap dengan data destinasi
  // static Future<List<Map<String, dynamic>>> fetchBookingsByUser(
  //   String userId,
  // ) async {
  //   try {
  //     // Ambil semua bookings
  //     final bookingsResp = await http.get(Uri.parse('$baseUrl/bookings.json'));
  //     final destinationsResp = await http.get(
  //       Uri.parse('$baseUrl/destinations.json'),
  //     );

  //     if (bookingsResp.statusCode != 200 ||
  //         destinationsResp.statusCode != 200) {
  //       return [];
  //     }

  //     final Map<String, dynamic>? bookingsData = json.decode(bookingsResp.body);
  //     final Map<String, dynamic>? destData = json.decode(destinationsResp.body);
  //     if (bookingsData == null) return [];

  //     final List<Map<String, dynamic>> result = [];

  //     for (var entry in bookingsData.entries) {
  //       final booking = entry.value as Map<String, dynamic>;
  //       if (booking['userId'] == userId) {
  //         final destId = booking['destinationId'];
  //         final dest = destData?[destId] as Map<String, dynamic>?;

  //         result.add({
  //           'bookingId': entry.key,
  //           'destinationId': destId,
  //           'bookingDate': booking['bookingDate'],
  //           'paymentTimeStamp': booking['paymentTimeStamp'],
  //           'quantity': booking['quantity'],
  //           'totalPrice': booking['totalPrice'],
  //           'userId': booking['userId'],
  //           // Data destinasi
  //           'name': dest?['name'] ?? 'Tanpa Nama',
  //           'location': dest?['location'] ?? 'Tidak diketahui',
  //           'description': dest?['description'] ?? '',
  //           'price': dest?['price'] ?? 0,
  //           'imageUrl': dest?['imageUrl'] ?? '',
  //         });
  //       }
  //     }

  //     return result;
  //   } catch (e) {
  //     print('❌ Error fetchBookingsByUser: $e');
  //     return [];
  //   }
  // }

  // /// 🔹 Simpan review baru
  // static Future<bool> addReview(Map<String, dynamic> reviewData) async {
  //   try {
  //     // Ambil semua review
  //     final response = await http.get(Uri.parse('$baseUrl/reviews.json'));
  //     final Map<String, dynamic>? data = response.statusCode == 200
  //         ? json.decode(response.body)
  //         : {};

  //     // Generate ID review: rev001, rev002...
  //     int nextNumber = 1;
  //     if (data != null && data.isNotEmpty) {
  //       final ids = data.keys
  //           .where((k) => k.startsWith('rev'))
  //           .map((k) => int.tryParse(k.replaceAll('rev', '')) ?? 0)
  //           .toList();
  //       if (ids.isNotEmpty)
  //         nextNumber = ids.reduce((a, b) => a > b ? a : b) + 1;
  //     }

  //     final newId = 'rev${nextNumber.toString().padLeft(3, '0')}';

  //     final putResp = await http.put(
  //       Uri.parse('$baseUrl/reviews/$newId.json'),
  //       body: json.encode(reviewData),
  //     );

  //     return putResp.statusCode == 200;
  //   } catch (e) {
  //     print('❌ Error addReview: $e');
  //     return false;
  //   }
  // }

  // /// 🔹 Ambil semua destinasi
  // static Future<List<Map<String, dynamic>>> getAllDestinations() async {
  //   try {
  //     final response = await http.get(Uri.parse('$baseUrl/destinations.json'));

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body) as Map<String, dynamic>?;

  //       if (data == null) return [];

  //       // Konversi menjadi list + sisipkan ID (key Firebase)
  //       final List<Map<String, dynamic>> list = [];

  //       data.forEach((key, value) {
  //         final dest = Map<String, dynamic>.from(value);
  //         dest["id"] = key;
  //         list.add(dest);
  //       });

  //       return list;
  //     } else {
  //       print("❌ Gagal fetch destinations: ${response.body}");
  //       return [];
  //     }
  //   } catch (e) {
  //     print("❌ Error getAllDestinations: $e");
  //     return [];
  //   }
  // }

  // /// 🔹 Ambil semua users
  // static Future<List<Map<String, dynamic>>> getAllUsers() async {
  //   try {
  //     final response = await http.get(Uri.parse('$baseUrl/users.json'));

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body) as Map<String, dynamic>?;

  //       if (data == null) return [];

  //       final List<Map<String, dynamic>> list = [];

  //       data.forEach((key, value) {
  //         final user = value as Map<String, dynamic>;
  //         user["id"] = key;
  //         list.add(user);
  //       });

  //       return list;
  //     } else {
  //       print("❌ Gagal fetch users: ${response.body}");
  //       return [];
  //     }
  //   } catch (e) {
  //     print("❌ Error getAllUsers: $e");
  //     return [];
  //   }
  // }

  // /// 🔹 Ambil semua bookings
  // static Future<List<Map<String, dynamic>>> getAllBookings() async {
  //   try {
  //     final response = await http.get(Uri.parse('$baseUrl/bookings.json'));

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body) as Map<String, dynamic>?;

  //       if (data == null) return [];

  //       final List<Map<String, dynamic>> list = [];

  //       data.forEach((key, value) {
  //         final book = value as Map<String, dynamic>;
  //         book["id"] = key;
  //         list.add(book);
  //       });

  //       return list;
  //     } else {
  //       print("❌ Gagal fetch bookings: ${response.body}");
  //       return [];
  //     }
  //   } catch (e) {
  //     print("❌ Error getAllBookings: $e");
  //     return [];
  //   }
  // }

  // /// 🔹 Ambil semua reviews
  // static Future<List<Map<String, dynamic>>> getAllReviews() async {
  //   try {
  //     final response = await http.get(Uri.parse('$baseUrl/reviews.json'));

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body) as Map<String, dynamic>?;

  //       if (data == null) return [];

  //       final List<Map<String, dynamic>> list = [];

  //       data.forEach((key, value) {
  //         final review = value as Map<String, dynamic>;
  //         review["id"] = key;
  //         list.add(review);
  //       });

  //       return list;
  //     } else {
  //       print("❌ Gagal fetch reviews: ${response.body}");
  //       return [];
  //     }
  //   } catch (e) {
  //     print("❌ Error getAllReviews: $e");
  //     return [];
  //   }
  // }

  // /// 🔹 Tambah destinasi baru (return newId)
  // static Future<String?> addDestination(Map<String, dynamic> data) async {
  //   try {
  //     final response = await http.get(Uri.parse('$baseUrl/destinations.json'));
  //     final Map<String, dynamic>? result = response.statusCode == 200
  //         ? json.decode(response.body)
  //         : null;

  //     int nextNumber = 1;

  //     if (result != null && result.isNotEmpty) {
  //       final numbers = result.keys
  //           .where((k) => k.startsWith("dest"))
  //           .map((k) => int.tryParse(k.replaceAll("dest", "")) ?? 0)
  //           .toList();

  //       if (numbers.isNotEmpty) {
  //         nextNumber = numbers.reduce((a, b) => a > b ? a : b) + 1;
  //       }
  //     }

  //     final newId = "dest${nextNumber.toString().padLeft(3, '0')}";

  //     final putResponse = await http.put(
  //       Uri.parse("$baseUrl/destinations/$newId.json"),
  //       body: json.encode(data),
  //     );

  //     return putResponse.statusCode == 200 ? newId : null;
  //   } catch (e) {
  //     print("❌ Error addDestination: $e");
  //     return null;
  //   }
  // }

  // /// 🔹 Update destinasi
  // static Future<bool> updateDestination(
  //   String destinationId,
  //   Map<String, dynamic> data,
  // ) async {
  //   try {
  //     final response = await http.patch(
  //       Uri.parse("$baseUrl/destinations/$destinationId.json"),
  //       body: json.encode(data),
  //     );

  //     return response.statusCode == 200;
  //   } catch (e) {
  //     print("❌ Error updateDestination: $e");
  //     return false;
  //   }
  // }

  // /// 🔹 Hapus destinasi
  // static Future<bool> deleteDestination(String destinationId) async {
  //   try {
  //     final response = await http.delete(
  //       Uri.parse("$baseUrl/destinations/$destinationId.json"),
  //     );

  //     return response.statusCode == 200;
  //   } catch (e) {
  //     print("❌ Error deleteDestination: $e");
  //     return false;
  //   }
  // }

  // /// 🔹 Update user
  // static Future<bool> updateUser(String id, Map<String, dynamic> data) async {
  //   try {
  //     // Jika "password" ada di data, hash dulu
  //     if (data.containsKey("password")) {
  //       data["password"] = hashPassword(data["password"]);
  //     }

  //     final url = Uri.parse('$baseUrl/users/$id.json');
  //     final response = await http.patch(url, body: json.encode(data));

  //     return response.statusCode == 200;
  //   } catch (e) {
  //     print("❌ Error updateUser: $e");
  //     return false;
  //   }
  // }

  // /// 🔹 Delete user
  // static Future<bool> deleteUser(String id) async {
  //   try {
  //     final response = await http.delete(Uri.parse('$baseUrl/users/$id.json'));

  //     return response.statusCode == 200;
  //   } catch (e) {
  //     print("❌ Error deleteUser: $e");
  //     return false;
  //   }
  // }
}
