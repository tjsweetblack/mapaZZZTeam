import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Blog {
  final String title;
  final String imageUrl;
  final String body;

  Blog({required this.title, required this.imageUrl, required this.body});

  factory Blog.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return Blog(
      title: data?['title'] ?? '',
      imageUrl: data?['imageUrl'] ?? '',
      body: data?['body'] ?? '',
    );
  }
}

class BlogPage extends StatelessWidget {
  const BlogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('blog').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.black));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No blogs found'));
          }

          final blogs = snapshot.data!.docs
              .map((doc) => Blog.fromFirestore(
                  doc as DocumentSnapshot<Map<String, dynamic>>))
              .toList();

          return ListView.builder(
            itemCount: blogs.length,
            itemBuilder: (context, index) {
              final blog = blogs[index];
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.network(
                        blog.imageUrl,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(
                            height: 150,
                            width: double.infinity,
                            child: Center(
                                child: Text('Image could not be loaded')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      blog.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      blog.body.length > 150
                          ? '${blog.body.substring(0, 150)}...'
                          : blog.body,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
