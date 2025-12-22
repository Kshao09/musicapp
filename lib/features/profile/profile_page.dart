import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(radius: 36, child: Icon(Icons.person, size: 36)),
            const SizedBox(height: 12),
            const Text('Kenny Shao', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            Card(
              child: Column(
                children: const [
                  ListTile(leading: Icon(Icons.settings), title: Text('Settings')),
                  Divider(height: 0),
                  ListTile(leading: Icon(Icons.history), title: Text('Listening History')),
                  Divider(height: 0),
                  ListTile(leading: Icon(Icons.logout), title: Text('Logout')),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
