import 'package:flutter/material.dart';
import '../services/firebase_realtime_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stronghub/main.dart';

class NewsPageAdmin extends StatefulWidget {
  const NewsPageAdmin({super.key});

  @override
  State<NewsPageAdmin> createState() => _NewsPageAdminState();
}

class _NewsPageAdminState extends State<NewsPageAdmin> {
  List<Map<String, dynamic>> newsList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() => isLoading = true);
    try {
      final news = await FirebaseRealtimeService.fetchAllNews();
      setState(() {
        newsList = news;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("❌ Error loading news: $e");
    }
  }

  Future<void> _addNewsDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final adminEmail = prefs.getString('adminEmail') ?? '';
    String? createdBy;

    // Ambil UID admin dari email
    if (adminEmail.isNotEmpty) {
      createdBy = await FirebaseRealtimeService.fetchAdminUidByEmail(
        adminEmail,
      );
    }
    createdBy ??= 'unknown';

    final titleController = TextEditingController();
    final contentController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height *
                0.8, // maksimal 80% tinggi layar
            maxWidth:
                MediaQuery.of(context).size.width * 0.8, // 80% lebar layar
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Tambah Berita",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: "Judul Berita",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      labelText: "Isi Berita",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.multiline,
                    minLines: 4,
                    maxLines: 8,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Batal"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Simpan"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    final success = await FirebaseRealtimeService.addNewsWithId(
      title: titleController.text.trim(),
      content: contentController.text.trim(),
      createdBy: createdBy,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Berita berhasil ditambahkan")),
      );
      _loadNews();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal menambahkan berita")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewsDialog,
        backgroundColor: redDark,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: "Tambah Berita",
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: newsList.length,
        itemBuilder: (context, index) {
          final news = newsList[index];
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
                  Text(
                    news['title'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(news['content']),
                  const SizedBox(height: 8),
                  Text(
                    "Dibuat pada: ${news['createdAt']}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
