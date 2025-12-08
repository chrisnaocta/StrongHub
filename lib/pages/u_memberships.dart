import 'package:flutter/material.dart';

class MembershipsPageUser extends StatelessWidget {
  const MembershipsPageUser({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Membership User")),
      body: const Center(
        child: Text("Membership User", style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
