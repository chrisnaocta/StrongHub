import 'package:flutter/material.dart';

class StatusPageUser extends StatelessWidget {
  const StatusPageUser({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Status User")),
      body: const Center(
        child: Text("Status User", style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
