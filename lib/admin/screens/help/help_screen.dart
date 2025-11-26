import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Help & Support',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          _buildSection(
            'Frequently Asked Questions',
            [
              _buildFAQItem(
                'How do I add a new menu item?',
                'Go to Menu Items → Click the + button → Fill in the details and save.',
              ),
              _buildFAQItem(
                'How do I generate a QR code for a table?',
                'Go to Tables → Click the QR icon on any table card.',
              ),
              _buildFAQItem(
                'How do I update order status?',
                'Go to Orders → Click on an order → Use the status dropdown to change status.',
              ),
              _buildFAQItem(
                'How do I track inventory?',
                'Go to Inventory → Select an item → Toggle "Track Stock" and set the stock count.',
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          _buildSection(
            'Contact Support',
            [
              const ListTile(
                leading: Icon(Icons.email),
                title: Text('Email'),
                subtitle: Text('support@scanserve.com'),
              ),
              const ListTile(
                leading: Icon(Icons.phone),
                title: Text('Phone'),
                subtitle: Text('+91 1234567890'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          _buildSection(
            'Quick Links',
            [
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Documentation'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  // Open documentation
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('Video Tutorials'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  // Open tutorials
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          const Card(
            color: Colors.blue,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need More Help?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Our support team is available 24/7 to assist you with any questions or issues.',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(answer),
        ],
      ),
    );
  }
}
