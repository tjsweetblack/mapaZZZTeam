import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:auth_bloc/features/blog/ui/screens/blog_screen.dart'; // Import the Blog model

class BlogDetailPage extends StatelessWidget {
  final Blog blog;
  const BlogDetailPage({super.key, required this.blog});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: blog.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: blog.imageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(
                            child: CircularProgressIndicator(
                                color: Colors.black54)),
                      ),
                      errorWidget: (context, url, error) => const SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: Center(child: Text('Image could not be loaded')),
                      ),
                    )
                  : const SizedBox(
                      width: double.infinity,
                      height: 200,
                      child: Center(
                          child: Icon(Icons.image_not_supported,
                              size: 60, color: Colors.grey)),
                    ),
            ),
            const SizedBox(height: 20),
            Text(
              blog.title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.black),
            ),
            const SizedBox(height: 16),
            Text(
              blog.body,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
