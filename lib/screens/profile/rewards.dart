import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RewardsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Premios'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reward').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No rewards found.'));
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
              return _buildRewardItem(
                image: data['imageUrl'] ??
                    '', // Provide a default value if imageUrl is null
                title: data['title'] ??
                    '', // Provide a default value if title is null
                points: data['points'] ??
                    0, // Provide a default value if points is null
                buttonText:
                    'Reivindicar', // This should be handled based on user's claimed rewards
                buttonColor: Colors
                    .red, //  This should change based on whether the user can claim it
                strokeColor: const Color.fromARGB(255, 43, 43, 43),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildRewardItem({
    required String image,
    required String title,
    required int points,
    required String buttonText,
    required Color buttonColor,
    Color? strokeColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: strokeColor ?? Colors.grey.shade300,
          width: strokeColor != null ? 2.0 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                height: 80.0,
                child: image.isNotEmpty
                    ? Image.network(image)
                    : const Placeholder(), // Show placeholder if image URL is empty
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Nome:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(title),
            const SizedBox(height: 8.0),
            Row(
              children: <Widget>[
                const Icon(
                  Icons.star,
                  color: Colors.red,
                  size: 20.0,
                ),
                const SizedBox(width: 4.0),
                Text('pontos necessario: $points pontos'),
              ],
            ),
            const SizedBox(height: 16.0),
            Align(
              alignment: Alignment.bottomLeft,
              child: ElevatedButton(
                onPressed: () {
                  // Handle button press
                },
                child: Text(
                  buttonText,
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
