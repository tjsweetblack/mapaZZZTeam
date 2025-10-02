import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import CachedNetworkImage
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'blog_detail_page.dart';

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

  // Convert Blog to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'imageUrl': imageUrl,
      'body': body,
    };
  }

  // Create Blog from JSON for caching
  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      body: json['body'] ?? '',
    );
  }
}

class BlogPage extends StatefulWidget {
  const BlogPage({super.key});

  @override
  State<BlogPage> createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  List<Blog> _cachedBlogs = [];
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _loadCachedBlogs();
  }

  // Load cached blogs from SharedPreferences
  Future<void> _loadCachedBlogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_blogs');
      if (cachedData != null) {
        final List<dynamic> blogList = json.decode(cachedData);
        setState(() {
          _cachedBlogs = blogList.map((blog) => Blog.fromJson(blog)).toList();
        });
      }
    } catch (e) {
      print('Error loading cached blogs: $e');
    }
  }

  // Save blogs to cache
  Future<void> _saveBlogsToCache(List<Blog> blogs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final blogList = blogs.map((blog) => blog.toJson()).toList();
      await prefs.setString('cached_blogs', json.encode(blogList));
    } catch (e) {
      print('Error saving blogs to cache: $e');
    }
  }

  // Check internet connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isOffline ? Icons.wifi_off : Icons.article_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _isOffline ? 'No internet connection' : 'No blogs available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isOffline
                ? 'Please check your internet connection and try again'
                : 'Check back later for new blog posts',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (_isOffline && _cachedBlogs.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isOffline = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF008080),
                foregroundColor: Colors.white,
              ),
              child: const Text('View Cached Blogs'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unable to load blogs. Please try again later.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (_cachedBlogs.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isOffline = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF008080),
                foregroundColor: Colors.white,
              ),
              child: const Text('View Cached Blogs'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Blog', style: TextStyle(color: Colors.black)),
            if (_isOffline) ...[
              const SizedBox(width: 8),
              Icon(Icons.cloud_off, color: Colors.orange, size: 20),
              const SizedBox(width: 4),
              Text(
                'Offline',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final hasConnection = await _checkConnectivity();
              setState(() {
                _isOffline = !hasConnection;
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<bool>(
        future: _checkConnectivity(),
        builder: (context, connectivitySnapshot) {
          if (connectivitySnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF008080)),
            );
          }

          final isConnected = connectivitySnapshot.data ?? false;

          if (!isConnected) {
            setState(() {
              _isOffline = true;
            });

            if (_cachedBlogs.isEmpty) {
              return _buildEmptyState();
            }

            // Show cached blogs when offline
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.orange[100],
                  child: Row(
                    children: [
                      Icon(Icons.cloud_off,
                          color: Colors.orange[700], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Showing cached blogs (offline)',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildBlogList(_cachedBlogs)),
              ],
            );
          }

          // Online - use StreamBuilder
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('blog').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildErrorState();
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF008080)),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              final blogs = snapshot.data!.docs
                  .map((doc) => Blog.fromFirestore(
                      doc as DocumentSnapshot<Map<String, dynamic>>))
                  .toList();

              // Cache the blogs for offline use
              _saveBlogsToCache(blogs);

              return _buildBlogList(blogs);
            },
          );
        },
      ),
    );
  }

  Widget _buildBlogList(List<Blog> blogs) {
    return ListView.builder(
      itemCount: blogs.length,
      itemBuilder: (context, index) {
        final blog = blogs[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlogDetailPage(blog: blog),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.0), // Rounded corners
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16.0), // Margin around the container
              padding:
                  const EdgeInsets.all(16.0), // Padding inside the container
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: blog.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: blog.imageUrl,
                            width: double.infinity,
                            height: 150,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: double.infinity,
                              height: 150,
                              color: Colors.grey[300],
                              child: const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.black54)),
                            ),
                            errorWidget: (context, url, error) =>
                                const SizedBox(
                              height: 150,
                              width: double.infinity,
                              child: Center(
                                  child: Text('Image could not be loaded')),
                            ),
                          )
                        : const SizedBox(
                            width: double.infinity,
                            height: 150,
                            child: Center(
                                child: Icon(Icons.image_not_supported,
                                    size: 50, color: Colors.grey)),
                          ), // Fallback for empty URL
                  ),
                  const SizedBox(height: 12.0), // Increased spacing
                  Text(
                    blog.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0, // Increased font size
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8.0), // Increased spacing
                  Text(
                    blog.body.length > 150
                        ? '${blog.body.substring(0, 150)}...'
                        : blog.body,
                    style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14.0), // Slightly increased font size
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
